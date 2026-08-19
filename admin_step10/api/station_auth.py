import os
from functools import wraps
from flask import request, jsonify
from itsdangerous import URLSafeTimedSerializer, BadSignature, SignatureExpired

from rmi.proxies import get_station_operator_service

TOKEN_MAX_AGE_SECONDS = 8 * 60 * 60


def _serializer():
    secret = os.getenv('STATION_AUTH_SECRET') or os.getenv('SECRET_KEY') or 'dev-key'
    return URLSafeTimedSerializer(secret, salt='smart-fuel-station-auth-v1')


def create_station_token(operator):
    return _serializer().dumps(operator)


def load_station_token(token):
    return _serializer().loads(token, max_age=TOKEN_MAX_AGE_SECONDS)


def station_context():
    authorization = request.headers.get('Authorization', '')
    if not authorization.lower().startswith('bearer '):
        return None, ('Missing station authentication token', 'AUTH_REQUIRED', 401)

    token = authorization[7:].strip()
    if not token:
        return None, ('Missing station authentication token', 'AUTH_REQUIRED', 401)

    try:
        payload = load_station_token(token)
    except SignatureExpired:
        return None, ('Station session expired. Please login again.', 'AUTH_EXPIRED', 401)
    except BadSignature:
        return None, ('Invalid station authentication token', 'AUTH_INVALID', 401)

    if not isinstance(payload, dict) or payload.get('type') != 'station_operator':
        return None, ('Invalid station authentication token', 'AUTH_INVALID', 401)

    return payload, None


def require_station_auth(view):
    @wraps(view)
    def wrapper(*args, **kwargs):
        context, error = station_context()
        if error:
            message, code, status = error
            return jsonify({'success': False, 'message': message, 'code': code}), status
        request.station_context = context
        return view(*args, **kwargs)

    return wrapper


def register_station_auth_routes(blueprint):
    @blueprint.post('/login')
    def station_login():
        body = request.get_json(silent=True) or {}
        operator_code = str(body.get('operator_code') or '').strip()
        password = str(body.get('password') or '')

        if not operator_code or not password:
            return jsonify({
                'success': False,
                'message': 'Operator ID and password are required',
                'code': 'MISSING_CREDENTIALS',
            }), 400

        service = get_station_operator_service()
        if not service:
            return jsonify({
                'success': False,
                'message': 'Station authentication service is unavailable',
                'code': 'RMI_UNAVAILABLE',
            }), 503

        try:
            result = service.authenticate_operator(operator_code, password)
        except Exception as exc:
            return jsonify({
                'success': False,
                'message': 'Station authentication failed',
                'code': 'AUTH_ERROR',
                'details': str(exc),
            }), 500

        if not result:
            return jsonify({
                'success': False,
                'message': 'Invalid operator ID or password',
                'code': 'INVALID_CREDENTIALS',
            }), 401

        if result.get('error'):
            return jsonify({
                'success': False,
                'message': result['error'],
                'code': 'STATION_NOT_AVAILABLE',
            }), 403

        operator = result['operator']
        station = result['station']

        token = create_station_token({
            'type': 'station_operator',
            'operator_id': operator['id'],
            'user_id': operator['user_id'],
            'operator_code': operator['operator_code'],
            'station_id': station['id'],
        })

        return jsonify({
            'success': True,
            'message': 'Station login successful',
            'token': token,
            'operator': operator,
            'station': station,
            'expires_in': TOKEN_MAX_AGE_SECONDS,
        })

    @blueprint.get('/session')
    @require_station_auth
    def station_session():
        return jsonify({
            'success': True,
            'session': request.station_context,
        })

    return blueprint
