# Turco - Gestión de Turnos de Peluquería

Aplicación móvil desarrollada en Flutter para la gestión de turnos de una peluquería mixta.

## Información del Estudiante
- **Nombre:** Dairon Vilau
- **Application ID:** com.daironvilau.turco
- **Versión de Flutter:** 3.35.2

## Tecnologías
- Framework: Flutter (Dart)
- Navegación: go_router
- Arquitectura: MVVM (ChangeNotifier)
- Diseño: Material 3 (Tema claro/oscuro)

## Cómo inicializar el proyecto
1. Clonar el repositorio: `git clone https://github.com/Dairon96/Turco.git`
2. Entrar a la carpeta: `cd Turco`
3. Descargar dependencias: `flutter pub get`
4. Ejecutar: `flutter run`

## Cómo generar el APK en modo Release
Ejecutar en la terminal: `flutter build apk --release`
El archivo se generará en: `build/app/outputs/flutter-apk/app-release.apk`
*(También está disponible en la sección Releases de este repositorio).*

## Estructura de Carpetas (lib/)
- `core/`: Utilidades de formato.
- `data/`: Datos de prueba.
- `models/`: Entidades (Turno, Cliente, etc.).
- `theme/`: Tema global.
- `viewmodels/`: Lógica de estado y reglas de negocio.
- `views/`: Pantallas de la interfaz.
- `router.dart`: Navegación.
- `main.dart`: Punto de entrada.