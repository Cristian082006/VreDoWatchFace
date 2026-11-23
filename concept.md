# VreDo — concept cadran Garmin fēnix 8

## Dispozitiv țintă

- Garmin fēnix 8, 47 mm, AMOLED, ecran rotund de 454 × 454 px (Connect IQ API 6.0).
- Macheta `preview.svg` este desenată la această rezoluție.

## Dispunere

- Cadran analogic inspirat de fotografia de referință, cu cadran întunecat, cifre orare și marcaje aurii. Textul „FĒNIX” este eliminat.
- Ziua, data și luna rămân vizibile discret sub cifra 12.
- Vremea este widgetul central, cu pictogramă mare, temperatură și localitate.
- Pulsul, pașii, caloriile zilnice Garmin și bateria apar ca patru widgeturi compacte cu pictogramă și valoare, așezate în jurul vremii.
- Acele analogice păstrează ora lizibilă; ecranul activ și AOD folosesc aceeași dispunere, cu desen simplificat și culori estompate în AOD.
- Pictograma meteo reflectă condiția curentă (soare, nori, ploaie, ninsoare și alte condiții disponibile). Datele se actualizează odată cu datele meteo Garmin.

## Etapa următoare

- Minima și maxima zilei, probabilitatea de ploaie, viteza vântului și umiditatea vor fi adăugate într-o etapă ulterioară.

## Note pentru implementarea Connect IQ

- Temperatura curentă și localitatea se citesc din `Toybox.Weather`.
- Minima/maxima, probabilitatea precipitațiilor, vântul și umiditatea sunt planificate pentru etapa următoare.
- Garmin actualizează de regulă vremea aproximativ la 15 minute când ceasul are conexiune; datele nu sunt disponibile în toate regiunile și locația prognozei poate fi aleasă separat de poziția ceasului.
- API-ul meteo expune probabilitatea precipitațiilor, nu neapărat cantitatea acumulată.
- Pictogramele și valorile folosesc desenare Connect IQ și font vectorial pentru lizibilitate.
- Pentru răsărit/apus se folosesc API-urile meteo Garmin. Localitatea poate lipsi în funcție de furnizor și permisiuni; va trebui să avem un fallback.
- Numărul de pași și caloriile zilei, pulsul și altitudinea pot lipsi temporar sau pot avea cerințe API/permisiuni specifice.
- Fēnix 8 de 47 mm Solar folosește un ecran MIP de 260 × 260 px; acest proiect vizează varianta AMOLED și macheta nu este încă adaptată pentru Solar.

## Valori demonstrative în machetă

Toate valorile afișate în previzualizare sunt fictive; macheta arată doar ierarhia și densitatea informației.
