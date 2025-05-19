# PDI Project – Flutter Didactics Support System

## Instrukcja uruchomienia aplikacji

Instalację przeprowadzono na systemie Windows 10, wersja 22H2 (kompilacja systemu operacyjnego: 19045.5737)

Uruchomienie aplikacji w przeglądarce wymaga najmniej konfiguracji, w związku z czym jest to metoda rekomendowana.

### Wersja podstawowa (uruchomienie w przeglądarce)

1. Zainstaluj Fluttera zgodnie z instrukcją: [`https://docs.flutter.dev/get-started/install`](https://docs.flutter.dev/get-started/install)

2. Sprawdź konfigurację Fluttera
   W terminalu uruchom: `flutter doctor`. Jeśli pojawią się błędy, postępuj zgodnie z opisanymi zaleceniami.

   > Do uruchomienia w przeglądarce nie są wymagane: Android toolchain, Visual Studio, Android Studio oraz VS Code.

3. Otwórz terminal i przejdź do folderu z projektem

4. Pobierz zależności projektu - w terminalu w katalogu głównym projektu wpisz `flutter pub get`

5. Sprawdź dostępne urządzenia poleceniem `flutter devices`

6. Uruchom aplikację w przeglądarce (Chrome) `flutter run -d chrome`

---

### Opcjonalnie: uruchomienie na emulatorze

Uwaga! Wymaga to więcej konfiguracji związanej z instalacją i uruchomieniem emulatora

1. Wykonaj kroki 1–4 jak wyżej.

2. Sprawdź dostępne emulatory poleceniem `flutter emulators`

3. Jeśli emulator nie istnieje, utwórz nowy emulator poleceniem `flutter emulators --create flutter_emulator`

   > Wymagane jest zainstalowane Android SDK.

4. Uruchom emulator poleceniem `flutter emulators --launch flutter_emulator`

5. Sprawdź identyfikator urządzenia poleceniem `flutter devices` (druga kolumna)

6. Uruchom aplikację na emulatorze `flutter run -d <device-id>`
