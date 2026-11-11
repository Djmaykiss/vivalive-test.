import { AccessToken, TrackSource } from 'livekit-server-sdk';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
const SUPABASE_PUBLISHABLE_KEY = Deno.env.get('SUPABASE_ANON_KEY');
const cors = {'Access-Control-Allow-Origin':'https://vivalive-test.netlify.app','Access-Control-Allow-Methods':'POST, OPTIONS','Access-Control-Allow-Headers':'authorization, apikey, content-type, x-client-info'};

const reply = (status, body) => Response.json(body, {status, headers: {...cors, 'Cache-Control':'no-store'}});
export default async function handler(request) {
  if (request.method === 'OPTIONS') return new Response(null,{status:204,headers:cors});
  if (request.method !== 'POST') return reply(405, {error:'Usa POST.'});
  const authorization = request.headers.get('authorization') || '';
  if (!/^Bearer [^\s]+$/i.test(authorization)) return reply(401, {error:'Inicia sesión.'});
  const body = await request.json().catch(() => null);
  if (!/^[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}$/i.test(body?.roomId) ||
      !['host','viewer'].includes(body?.role)) return reply(400, {error:'Sala o rol inválido.'});
  const headers = {authorization, apikey: SUPABASE_PUBLISHABLE_KEY};
  try {
    const auth = await fetch(SUPABASE_URL + '/auth/v1/user', {headers});
    if (!auth.ok) return reply(auth.status >= 500 ? 503 : 401, {error:'No se pudo validar la sesión.'});
    const user = await auth.json();
    if (!user.id || !user.email_confirmed_at) return reply(403, {error:'Confirma tu correo.'});
    const query = new URLSearchParams({id:'eq.' + body.roomId, status:'eq.live', select:'host_id,heartbeat_at'});
    const response = await fetch(SUPABASE_URL + '/rest/v1/vl_rooms?' + query, {headers});
    if (!response.ok) return reply(503, {error:'No se pudo consultar la sala.'});
    const [room] = await response.json();
    if (!room || (body.role === "viewer" && Date.parse(room.heartbeat_at) < Date.now()-70000)) return reply(404,{error:'La transmisión terminó.'});
    const publish = body.role === 'host';
    if (publish && room.host_id !== user.id) return reply(403,{error:'Solo el creador puede transmitir.'});
    const url = 'wss://vivalive-qeo7133f.livekit.cloud';
    const key = Deno.env.get('LIVEKIT_API_KEY');
    const secret = Deno.env.get('LIVEKIT_API_SECRET');
    if (!url?.startsWith('wss://') || !key || !secret) return reply(503,{error:'LiveKit todavía no está configurado.'});
    const identity = publish ? user.id : user.id + '/' + crypto.randomUUID();
    const token = new AccessToken(key, secret, {identity, ttl:'2m', name:String(user.user_metadata?.display_name || 'Usuario').slice(0,40)});
    token.addGrant({roomJoin:true, room:'vivalive/' + room.host_id + '/' + body.roomId,
      canPublish:publish, canSubscribe:!publish, canPublishData:true, canUpdateOwnMetadata:false,
      ...(publish ? {canPublishSources:[TrackSource.CAMERA,TrackSource.MICROPHONE]} : {})});
    return reply(200,{url, token:await token.toJwt()});
  } catch {
    return reply(503,{error:'El servicio de transmisión no está disponible.'});
  }
}
