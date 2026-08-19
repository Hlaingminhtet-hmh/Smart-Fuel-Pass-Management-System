import base64, hashlib, hmac, json, os, time
from functools import wraps
from flask import jsonify, request
TOKEN_MAX_AGE_SECONDS=8*60*60
def _secret(): return (os.getenv('USER_AUTH_SECRET') or os.getenv('SECRET_KEY','dev-key')).encode()
def create_user_token(payload):
    p=dict(payload); p.update(type='user',iat=int(time.time()),exp=int(time.time())+TOKEN_MAX_AGE_SECONDS)
    raw=json.dumps(p,separators=(',',':'),sort_keys=True).encode(); enc=base64.urlsafe_b64encode(raw).decode().rstrip('=')
    sig=hmac.new(_secret(),enc.encode(),hashlib.sha256).hexdigest(); return f'{enc}.{sig}'
def verify_user_token(token):
    if not token or '.' not in token: return None
    enc,sig=token.rsplit('.',1); expected=hmac.new(_secret(),enc.encode(),hashlib.sha256).hexdigest()
    if not hmac.compare_digest(sig,expected): return None
    try:
        pad='='*(-len(enc)%4); p=json.loads(base64.urlsafe_b64decode((enc+pad).encode()).decode())
    except Exception: return None
    return p if p.get('type')=='user' and int(p.get('exp',0))>=int(time.time()) else None
def require_user_auth(fn):
    @wraps(fn)
    def wrapper(*args,**kwargs):
        h=request.headers.get('Authorization',''); token=h[7:].strip() if h.lower().startswith('bearer ') else None
        ctx=verify_user_token(token)
        if not ctx: return jsonify({'success':False,'message':'Authentication required','code':'AUTH_REQUIRED'}),401
        request.user_context=ctx; return fn(*args,**kwargs)
    return wrapper
