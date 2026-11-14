# VreDo — concept cadran Garmin fēnix 8

## Dispozitiv țintă

- Garmin fēnix 8, 47 mm, AMOLED, ecran rotund de 454 × 454 px (Connect IQ API 6.0).
- Macheta `preview.svg` este desenată la această rezoluție.

## Dispunere

- Cadran AMOLED rotund, cu un inel discret și fundal întunecat adaptat condiției meteo.
- Interfața folosește carduri cu pictograme și valori alăturate, fără nume de câmpuri. Data și widgetul meteo sunt sus, ora mare în centru, iar pulsul, următorul eveniment solar, pașii, caloriile, altitudinea și bateria sunt grupate în două rânduri jos.
- Ora mare traversează centrul; toate valorile rămân în cercul activ al ecranului.
- Pictograma și accentul din zona meteo se schimbă după condiția curentă (soare, nori, ploaie, ninsoare). Un ciclu de animații în fundal ar consuma baterie și ar reduce lizibilitatea; condiția meteo poate fi actualizată când se reîmprospătează datele.

## Note pentru implementarea Connect IQ

- Temperatura, maxima/minima, vântul și probabilitatea precipitațiilor se pot citi din `Toybox.Weather`.
- Garmin actualizează de regulă vremea aproximativ la 15 minute când ceasul are conexiune; datele nu sunt disponibile în toate regiunile și locația prognozei poate fi aleasă separat de poziția ceasului.
- API-ul meteo expune probabilitatea precipitațiilor, nu neapărat cantitatea acumulată.
- Pictogramele și valorile folosesc desenare Connect IQ și font vectorial pentru lizibilitate.
- Pentru răsărit/apus se folosesc API-urile meteo Garmin. Localitatea poate lipsi în funcție de furnizor și permisiuni; va trebui să avem un fallback.
- Numărul de pași și caloriile zilei, pulsul și altitudinea pot lipsi temporar sau pot avea cerințe API/permisiuni specifice.
- Fēnix 8 de 47 mm Solar folosește un ecran MIP de 260 × 260 px; acest proiect vizează varianta AMOLED și macheta nu este încă adaptată pentru Solar.

## Valori demonstrative în machetă

Toate valorile afișate în previzualizare sunt fictive; macheta arată doar ierarhia și densitatea informației.
