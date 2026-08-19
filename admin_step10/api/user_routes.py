from flask import Blueprint, jsonify, request
from database.db import SupabaseDB
from rmi.proxies import get_user_service,get_vehicle_service,get_fuel_service
from api.user_auth import create_user_token,require_user_auth,TOKEN_MAX_AGE_SECONDS
user_api=Blueprint('user_api',__name__,url_prefix='/api/v1/user')
def err(m,c,s=400): return jsonify({'success':False,'message':m,'code':c}),s
@user_api.post('/register')
def register():
 b=request.get_json(silent=True) or {}; nid=str(b.get('national_id','')).strip(); name=str(b.get('name','')).strip(); phone=str(b.get('phone','')).strip(); pw=str(b.get('password',''))
 if not all([nid,name,phone,pw]): return err('National ID, name, phone and password are required','MISSING_FIELDS')
 if len(pw)<8: return err('Password must be at least 8 characters','WEAK_PASSWORD')
 svc=get_user_service()
 if not svc: return err('User service unavailable','RMI_UNAVAILABLE',503)
 u=svc.register_user(nid,name,phone,pw)
 if not u or u.get('error'): return err((u or {}).get('error','Registration failed'),'REGISTRATION_FAILED')
 tok=create_user_token({'user_id':int(u['id']),'national_id':nid}); u.pop('password_hash',None)
 return jsonify({'success':True,'token':tok,'expires_in':TOKEN_MAX_AGE_SECONDS,'user':u}),201
@user_api.post('/login')
def login():
 b=request.get_json(silent=True) or {}; nid=str(b.get('national_id','')).strip(); pw=str(b.get('password',''))
 if not nid or not pw: return err('National ID and password are required','MISSING_CREDENTIALS')
 svc=get_user_service()
 if not svc: return err('User service unavailable','RMI_UNAVAILABLE',503)
 u=svc.authenticate_user(nid,pw)
 if not u: return err('Invalid National ID or password','INVALID_CREDENTIALS',401)
 if u.get('is_admin') or u.get('role') in {'admin','station_operator'}: return err('Use the appropriate management app','WRONG_CLIENT',403)
 tok=create_user_token({'user_id':int(u['id']),'national_id':nid}); u.pop('password_hash',None)
 return jsonify({'success':True,'token':tok,'expires_in':TOKEN_MAX_AGE_SECONDS,'user':u})
@user_api.get('/vehicles')
@require_user_auth
def vehicles():
 vs,fs=get_vehicle_service(),get_fuel_service()
 if not vs or not fs: return err('Vehicle/Fuel service unavailable','RMI_UNAVAILABLE',503)
 rows=[]
 for v in (vs.get_vehicles_by_user(str(request.user_context['user_id'])) or []):
  x=dict(v); q=fs.check_available_quota(str(v['id']))
  if q and not q.get('error'): x['quota']=q
  rows.append(x)
 return jsonify({'success':True,'vehicles':rows})
def _registry(plate):
 r=SupabaseDB().get_client().table('admin_vehicle_registry').select('*').eq('plate_number',plate).limit(1).execute(); return r.data[0] if r.data else None
@user_api.post('/vehicles/check')
@require_user_auth
def check_vehicle():
 b=request.get_json(silent=True) or {}
 plate=str(b.get('plate_number','')).strip().upper()
 owner_name=str(b.get('owner_name','')).strip()
 national_id=str(b.get('national_id','')).strip()
 vehicle_type=str(b.get('vehicle_type','')).strip()
 if not plate:return err('Plate number is required','MISSING_PLATE')
 reg=_registry(plate)
 if not reg:return err('This vehicle is not in the official registry','VEHICLE_NOT_AUTHORIZED',404)
 if reg.get('status')!='approved':return err(f"Vehicle is not approved (status: {reg.get('status')})",'VEHICLE_NOT_APPROVED',403)
 if owner_name and owner_name.casefold()!=str(reg.get('owner_name','')).strip().casefold():
  return err('Owner name does not match the official registry','OWNER_MISMATCH',403)
 if national_id and str(reg.get('owner_national_id') or '').strip() != national_id:
  return err('National ID does not match the official registry','NATIONAL_ID_MISMATCH',403)
 if vehicle_type and vehicle_type != str(reg.get('vehicle_type','')).strip():
  return err('Vehicle type does not match the official registry','VEHICLE_TYPE_MISMATCH',403)
 vs=get_vehicle_service()
 if vs and vs.get_vehicle_by_plate(plate):return err('This vehicle is already registered to a user','VEHICLE_ALREADY_CLAIMED',409)
 return jsonify({'success':True,'vehicle':reg})
@user_api.post('/vehicles/claim')
@require_user_auth
def claim_vehicle():
 b=request.get_json(silent=True) or {}
 plate=str(b.get('plate_number','')).strip().upper()
 owner_name=str(b.get('owner_name','')).strip()
 national_id=str(b.get('national_id','')).strip()
 vehicle_type=str(b.get('vehicle_type','')).strip()
 if not plate:return err('Plate number is required','MISSING_PLATE')
 reg=_registry(plate)
 if not reg:return err('This vehicle is not in the official registry','VEHICLE_NOT_AUTHORIZED',404)
 if reg.get('status')!='approved':return err(f"Vehicle is not approved (status: {reg.get('status')})",'VEHICLE_NOT_APPROVED',403)
 if owner_name and owner_name.casefold()!=str(reg.get('owner_name','')).strip().casefold():
  return err('Owner name does not match the official registry','OWNER_MISMATCH',403)
 if national_id and str(reg.get('owner_national_id') or '').strip() != national_id:
  return err('National ID does not match the official registry','NATIONAL_ID_MISMATCH',403)
 if vehicle_type and vehicle_type != str(reg.get('vehicle_type','')).strip():
  return err('Vehicle type does not match the official registry','VEHICLE_TYPE_MISMATCH',403)
 vs=get_vehicle_service()
 if not vs:return err('Vehicle service unavailable','RMI_UNAVAILABLE',503)
 r=vs.claim_approved_vehicle(str(request.user_context['user_id']),plate)
 if not r or r.get('error'):return err((r or {}).get('error','Claim failed'),'CLAIM_FAILED')
 return jsonify({'success':True,'message':'Vehicle registered successfully','vehicle':r}),201
@user_api.get('/history')
@require_user_auth
def user_history():
    """Return the authenticated user's recent fueling history across all vehicles."""
    vs, fs = get_vehicle_service(), get_fuel_service()
    if not vs or not fs:
        return err('Vehicle/Fuel service unavailable','RMI_UNAVAILABLE',503)

    vehicles = vs.get_vehicles_by_user(str(request.user_context['user_id'])) or []
    vehicle_ids = [int(v['id']) for v in vehicles if v.get('id') is not None]
    if not vehicle_ids:
        return jsonify({'success': True, 'transactions': []})

    transactions = []
    for vehicle_id in vehicle_ids:
        rows = fs.get_vehicle_transactions(str(vehicle_id), 50) or []
        vehicle = next((v for v in vehicles if int(v.get('id')) == vehicle_id), {})
        for row in rows:
            item = dict(row)
            item['plate_number'] = vehicle.get('plate_number', '-')
            item['fuel_type'] = item.get('fuel_type') or vehicle.get('fuel_type') or 'petrol_92'
            transactions.append(item)

    station_ids = sorted({str(t.get('station_id')) for t in transactions if t.get('station_id') is not None})
    station_map = {}
    if station_ids:
        try:
            station_rows = SupabaseDB().get_client().table('fuel_stations').select('id,station_name').in_('id', station_ids).execute().data or []
            station_map = {str(s['id']): s.get('station_name', 'Unknown Station') for s in station_rows}
        except Exception:
            station_map = {}

    for item in transactions:
        item['station_name'] = station_map.get(str(item.get('station_id')), 'Unknown Station')

    transactions.sort(key=lambda x: str(x.get('pumped_at') or ''), reverse=True)
    return jsonify({'success': True, 'transactions': transactions[:50]})

@user_api.get('/vehicles/<int:vehicle_id>/history')
@require_user_auth
def history(vehicle_id):
 vs,fs=get_vehicle_service(),get_fuel_service()
 v=vs.get_vehicle_by_id(str(vehicle_id)) if vs else None
 if not v:return err('Vehicle not found','VEHICLE_NOT_FOUND',404)
 if int(v.get('user_id') or 0)!=int(request.user_context['user_id']):return err('Forbidden','FORBIDDEN',403)
 return jsonify({'success':True,'transactions':fs.get_vehicle_transactions(str(vehicle_id),50) if fs else []})
@user_api.get('/vehicles/<int:vehicle_id>/qr')
@require_user_auth
def qr(vehicle_id):
 vs=get_vehicle_service(); v=vs.get_vehicle_by_id(str(vehicle_id)) if vs else None
 if not v:return err('Vehicle not found','VEHICLE_NOT_FOUND',404)
 if int(v.get('user_id') or 0)!=int(request.user_context['user_id']):return err('Forbidden','FORBIDDEN',403)
 return jsonify({'success':True,'vehicle':{'id':v['id'],'plate_number':v['plate_number']},'qr_code_image':v.get('qr_code_image'),'qr_code_data':v.get('qr_code_data')})
