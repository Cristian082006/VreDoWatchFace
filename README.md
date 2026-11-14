# VreDo Watch Face

Prototip Connect IQ pentru **Garmin fēnix 8, 47 mm AMOLED (454 × 454)**.

## Fișiere

- `preview.svg` — macheta vizuală cu valori demonstrative.
- `source/VreDoWatchFaceApp.mc` — aplicația și delegate-ul cadranului.
- `source/VreDoWatchFaceView.mc` — desenarea orei, vremii și indicatorilor.
- `manifest.xml` — ținta Connect IQ `fenix847mm` și permisiunile cadranului.
- `concept.md` — cerințe și limite API.

## Ce afișează prototipul

Interfața grupează valorile în carduri cu pictograme și valori alăturate, fără nume de câmpuri. Sus sunt data și widgetul meteo complet; ora mare ocupă centrul, iar pulsul, următorul eveniment solar, pașii, caloriile, altitudinea și bateria sunt în două rânduri de carduri jos.

Macheta folosește date fictive. Când ceasul nu are date meteo, poziționare sau valori de activitate, cadranul afișează marcaje de tip `--` ori un nume generic.

## Build

Proiectul folosește Garmin Connect IQ SDK și țintește `fenix847mm`. Ultimul build a fost compilat cu SDK 9.3.0 și rulat în simulatorul Connect IQ. Pentru a instala buildul pe ceas, compilează proiectul în VS Code cu extensia Monkey C și copiază `VreDo.prg` în `GARMIN/Apps`.

Fișierele generate de compilare (`.iq`, `.prg`, `*.debug.xml` și directoarele MIR) sunt excluse din Git; sursele și resursele rămân versionate.
