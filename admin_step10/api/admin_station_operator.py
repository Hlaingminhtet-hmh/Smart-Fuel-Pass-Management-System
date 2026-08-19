from flask import Blueprint, jsonify, request, session
from services.station_operator_service import StationOperatorService

admin_station_operator_api = Blueprint('admin_station_operator_api', __name__, url_prefix='/api/v1/admin/station-operators')
service = StationOperatorService()

def _admin_required(): return bool(session.get('is_admin'))

@admin_station_operator_api.post('')
def create_operator():
    if not _admin_required(): return jsonify({'success': False, 'message': 'Admin access required'}), 403
    body = request.get_json(silent=True) or {}
    try:
        result = service.create_operator(name=body.get('name',''), operator_code=body.get('operator_code',''), password=body.get('password',''), station_id=body.get('station_id'), phone=body.get('phone'), national_id=body.get('national_id'))
    except (TypeError, ValueError) as exc: return jsonify({'success': False, 'message': str(exc)}), 400
    except Exception as exc: return jsonify({'success': False, 'message': str(exc)}), 500
    if result.get('error'): return jsonify({'success': False, 'message': result['error']}), 400
    return jsonify(result), 201

@admin_station_operator_api.get('')
def list_operators():
    if not _admin_required(): return jsonify({'success': False, 'message': 'Admin access required'}), 403
    try:
        return jsonify({'success': True, 'operators': service.client.table('station_operators').select('id,user_id,station_id,operator_code,status,last_login_at,created_at,updated_at').order('id').execute().data or []})
    except Exception as exc: return jsonify({'success': False, 'message': str(exc)}), 500

@admin_station_operator_api.post('/<int:operator_id>/status')
def update_operator_status(operator_id):
    if not _admin_required(): return jsonify({'success': False, 'message': 'Admin access required'}), 403
    body = request.get_json(silent=True) or request.form.to_dict()
    status = body.get('status')
    if status not in {'active','inactive','suspended'}: return jsonify({'success': False, 'message': 'Invalid operator status'}), 400
    result = service.client.table('station_operators').update({'status': status}).eq('id', operator_id).execute()
    if not result.data: return jsonify({'success': False, 'message': 'Operator not found'}), 404
    return jsonify({'success': True, 'operator': result.data[0]})
