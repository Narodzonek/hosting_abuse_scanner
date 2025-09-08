# Test Suite for Hosting Abuse Scanner

## Opis

Ten katalog zawiera kompletny zestaw testów jednostkowych i integracyjnych dla skryptu `abuse_scanner.sh`. Testy wykorzystują framework **bats-core** do testowania skryptów Bash.

## Struktura

```
tests/
├── README.md           # Ten plik
├── test.bats          # Główny plik z testami
├── run_tests.sh       # Skrypt pomocniczy do uruchamiania testów
└── requirements.txt   # Wymagania do uruchomienia testów
```

## Wymagania

### 1. bats-core
```bash
# Ubuntu/Debian
sudo apt-get install bats

# macOS (Homebrew)
brew install bats-core

# Lub instalacja z GitHub
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local
```

### 2. Narzędzia systemowe
- `bash` (wersja 4.0+)
- `dd` (do tworzenia plików testowych)
- `grep`, `awk`, `sort` (standardowe narzędzia Unix)

## Uruchamianie testów

### Sposób 1: Bezpośrednio przez bats
```bash
cd tests
bats test.bats
```

### Sposób 2: Używając skryptu pomocniczego
```bash
cd tests
chmod +x run_tests.sh
./run_tests.sh
```

### Sposób 3: Uruchomienie konkretnego testu
```bash
bats test.bats -f "Basic functionality"
```

## Pokrycie testów

### Testy podstawowe
- ✅ **Basic functionality** - Identyfikacja podejrzanych plików w płaskiej strukturze
- ✅ **Negative test** - Brak raportowania czystych plików
- ✅ **Recursion test** - Znajdowanie plików w głęboko zagnieżdżonych katalogach
- ✅ **Empty directory test** - Obsługa pustych katalogów
- ✅ **Multiple files test** - Listowanie wielu podejrzanych plików

### Testy funkcjonalności
- ✅ **Archive detection** - Wykrywanie dużych archiwów
- ✅ **Media detection** - Wykrywanie dużych plików multimedialnych
- ✅ **Suspicious directory** - Wykrywanie podejrzanych nazw katalogów
- ✅ **Phishing detection** - Wykrywanie plików phishingowych (włączone/wyłączone)
- ✅ **Command line arguments** - Obsługa różnych opcji wiersza poleceń

### Testy interfejsu
- ✅ **Settings display** - Wyświetlanie aktualnych ustawień
- ✅ **Help display** - Wyświetlanie pomocy
- ✅ **Error handling** - Obsługa błędnych argumentów
- ✅ **Output file** - Zapis raportu do pliku

### Testy wydajności
- ✅ **Performance test** - Obsługa dużej liczby plików

## Struktura testów

Każdy test składa się z trzech części:

### 1. Arrange (Przygotowanie)
```bash
# Tworzenie plików testowych
create_suspicious_file "$TEST_DIR/movie.mkv" 200
create_test_file "$TEST_DIR/normal.txt" "Normal content"
```

### 2. Act (Wykonanie)
```bash
# Uruchomienie skryptu
output_file=$(run_scanner "--th-media 100")
exit_code=$?
```

### 3. Assert (Weryfikacja)
```bash
# Sprawdzenie kodu wyjścia
[ $exit_code -eq 0 ]

# Sprawdzenie zawartości
output_contains "$output_file" "movie.mkv"
! output_contains "$output_file" "normal.txt"
```

## Funkcje pomocnicze

### Tworzenie plików testowych
- `create_test_file(path, content)` - Tworzy plik z określoną zawartością
- `create_suspicious_file(path, size_mb)` - Tworzy podejrzany plik o określonym rozmiarze
- `create_archive_file(path, size_mb)` - Tworzy plik archiwum
- `create_media_file(path, size_mb)` - Tworzy plik multimedialny
- `create_suspicious_directory(path)` - Tworzy podejrzany katalog

### Sprawdzanie wyników
- `output_contains(file, text)` - Sprawdza czy plik zawiera tekst
- `count_occurrences(file, text)` - Liczy wystąpienia tekstu
- `run_scanner(args)` - Uruchamia skrypt z argumentami

## Interpretacja wyników

### Kod wyjścia
- `0` - Sukces
- `1` - Błąd (np. nieprawidłowe argumenty)
- Inne - Błędy systemowe

### Przykładowy output
```
 ✓ Basic functionality: Script identifies suspicious files in flat structure
 ✓ Negative test: Script does not report clean files
 ✓ Recursion test: Script finds suspicious files in deeply nested directories
 ✓ Empty directory test: Script handles empty directory gracefully
 ✓ Multiple files test: Script correctly lists all suspicious files

15 tests, 0 failures
```

## Rozszerzanie testów

### Dodawanie nowych testów
1. Dodaj nowy blok `@test "Nazwa testu" { ... }`
2. Użyj funkcji pomocniczych do tworzenia środowiska testowego
3. Sprawdź zarówno kod wyjścia jak i zawartość

### Przykład nowego testu
```bash
@test "New feature test: Script handles new functionality" {
    # Arrange
    create_test_file "$TEST_DIR/test.txt" "Test content"
    
    # Act
    output_file=$(run_scanner "--new-option")
    exit_code=$?
    
    # Assert
    [ $exit_code -eq 0 ]
    output_contains "$output_file" "Expected output"
}
```

## Debugowanie

### Uruchomienie z verbose output
```bash
bats test.bats --verbose
```

### Uruchomienie konkretnego testu
```bash
bats test.bats -f "Basic functionality"
```

### Sprawdzenie zawartości plików tymczasowych
Testy automatycznie czyszczą pliki tymczasowe, ale można dodać `set -x` na początku testu aby zobaczyć szczegóły wykonania.

## Integracja z CI/CD

### GitHub Actions
```yaml
- name: Run tests
  run: |
    cd tests
    bats test.bats
```

### Travis CI
```yaml
script:
  - cd tests && bats test.bats
```

## Uwagi

- Testy są odseparowane od głównego projektu
- Każdy test tworzy własne środowisko tymczasowe
- Testy automatycznie czyszczą po sobie
- Wszystkie ścieżki są względne do katalogu testów
- Testy sprawdzają zarówno funkcjonalność jak i wydajność
