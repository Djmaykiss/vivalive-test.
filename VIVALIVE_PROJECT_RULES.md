# Reglas permanentes del proyecto VivaLive

1. **No borrar nada ni cambiar funcionalidades, diseños, datos, rutas o comportamientos ya aprobados, salvo que el propietario lo solicite expresamente.** Esta regla aplica a Codex, agentes y futuras contribuciones.
2. Toda función nueva debe ser aditiva, compatible y reversible. Trabajar primero en una rama independiente antes de integrar a main.
3. No modificar proyectos, repositorios, servicios ni dominios ajenos a VivaLive.
4. Conservar el registro por correo confirmado, Supabase Auth, el backend de LiveKit, las salas, audio, video, chat, la estética aprobada, el formato 9:16 y el diseño responsive.
5. Cualquier actualización de base de datos debe añadir estructuras y políticas seguras sin borrar tablas ni registros existentes.
6. No exponer API Secrets, claves de servidor, tokens privados ni cuentas de servicio en frontend, repositorios o mensajes.
7. No activar servicios pagos, compras, regalos monetarios, monedas con valor real ni contenido adulto público sin autorización específica.
8. Antes de publicar, validar permisos, compilación, funcionalidad existente y funcionamiento entre dispositivos cuando sea posible. Nunca declarar una prueba real completada si solo se ejecutaron pruebas locales.
9. En caso de conflicto con estas reglas, detener el cambio incompatible y solicitar autorización expresa.

## Función añadida: Batallas + Tac tac

- Un creador que está transmitiendo invita a otro creador que también está en vivo.
- El invitado debe aceptar o rechazar; ninguna cámara se une automáticamente sin consentimiento.
- Al aceptar, cada audiencia puede ver a ambos creadores en la misma pantalla y un marcador de corazones.
- La ronda dura 5 minutos; los espectadores pueden pulsar Tac tac o tocar la imagen. El servidor registra votos y limita la frecuencia para evitar abusos.
- Los creadores participantes no votan por sí mismos ni en su propia batalla.
- El chat existente y los lives individuales se conservan.
- No hay pagos, regalos monetarios ni datos de espectadores falsos.
- Si no hay una batalla activa, el live conserva exactamente su funcionamiento individual anterior.

## Comprobación antes de liberar

- Dos cuentas con correo confirmado transmitiendo simultáneamente.
- Invitación, rechazo y aceptación desde dispositivos distintos.
- Video y audio de ambas cámaras en cada dispositivo.
- Tac tac por espectador y actualización compartida del marcador.
- Ganador o empate después de cinco minutos, y finalización manual.
- La transmisión individual, el registro, las sesiones, la navegación, el chat y el modo 9:16 continúan funcionando.
