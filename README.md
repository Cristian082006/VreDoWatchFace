# VreDo Watch Face

Prototip Connect IQ pentru **Garmin fēnix 8, 47 mm AMOLED (454 × 454)**.

## Fișiere

- `preview.svg` — macheta vizuală cu valori demonstrative.
- `source/VreDoWatchFaceApp.mc` — aplicația și delegate-ul cadranului.
- `source/VreDoWatchFaceView.mc` — desenarea orei, vremii și indicatorilor.
- `manifest.xml` — ținta Connect IQ `fenix847mm` și permisiunile cadranului.
- `concept.md` — cerințe și limite API.

## Ce afișează prototipul

Interfața nouă este analogică, cu cifre orare și marcaje aurii inspirate de fotografia de referință; textul „FĒNIX” a fost scos. Widgetul meteo mare stă în centru și afișează pictograma condiției actuale, temperatura și localitatea. Pulsul, pașii, caloriile Garmin și bateria au widgeturi compacte proprii, fiecare cu pictogramă și valoare. Ecranul AOD păstrează aceeași dispunere cu desen simplificat.

Minima/maxima zilei, șansa de ploaie, vântul și umiditatea sunt planificate pentru următoarea etapă.

Macheta folosește date fictive. Când ceasul nu are date meteo, poziționare sau valori de activitate, cadranul afișează marcaje de tip `--` ori un nume generic. Numele localității este furnizat de datele meteo Garmin memorate; cadranul nu poate declanșa reîmprospătarea lor, iar localitatea prognozei poate fi setată separat de poziția ceasului.

## Build

Proiectul folosește Garmin Connect IQ SDK și țintește `fenix847mm`. Ultimul build a fost compilat cu SDK 9.3.0 și rulat în simulatorul Connect IQ. Pentru a instala buildul pe ceas, compilează proiectul în VS Code cu extensia Monkey C și copiază `VreDo.prg` în `GARMIN/Apps`.

Fișierele generate de compilare (`.iq`, `.prg`, `*.debug.xml` și directoarele MIR) sunt excluse din Git; sursele și resursele rămân versionate.
