# TestFlight — Memo!

Dit document bevat de teksten die TestFlight vraagt en
het stappenplan om de eerste build bij testers te krijgen.

## Wat al klaarstaat

- Het project staat op versie 1.0, build 6 (`CURRENT_PROJECT_VERSION: 6` in
  project.yml), minimum iOS 17.0, bundle-id com.pivo7.memo, team VB6FS3N78T.
  Archiveren doe je in Xcode met "Any iOS Device (arm64)" → Product →
  **Archive**; de archive verschijnt dan in Window → **Organizer**. Het
  uploaden (stap 3) vraagt je Apple-account in Xcode.
- `ITSAppUsesNonExemptEncryption` staat op NO in het project, dus TestFlight
  slaat de export-compliance-vraag bij elke build over.
- Eén universeel 1024-appicoon (vereist voor de upload) zit in de asset catalog.
- De app is drietalig (nl/en/fr) met Nederlands als ontwikkeltaal.
- De StoreKit-configuratie `Memo.storekit` zit in het run-scheme, zodat de
  Gezinsversie lokaal te testen is vóór het product in App Store Connect staat.

## Stappenplan (eenmalig)

1. **App Store Connect → Apps → ➕ Nieuwe app**
   - Platform iOS, naam **Memo!**, primaire taal **Nederlands**,
     bundle-id **com.pivo7.memo**, SKU bv. `memo-001`.
2. **In-app-aankoop aanmaken** (mag ook later, maar vóór het testen van de
   Gezinsversie): niet-verbruiksartikel `com.pivo7.memo.gezin`,
   gezinsdeling aan — alle waarden staan in [appstore-tekst.md](appstore-tekst.md).
3. **Uploaden**: Xcode → Window → Organizer → archive "Memo 1.0 (6)" →
   **Distribute App → TestFlight & App Store → Upload**. Automatische
   ondertekening regelt het distributiecertificaat.
4. Na 5–15 minuten verwerken verschijnt de build onder het tabblad
   **TestFlight**. Vul daar de testinformatie in (teksten hieronder).
5. **Interne testers** (meteen, geen review): voeg jezelf en gezinsleden toe
   onder Interne testen. Zij krijgen een uitnodiging in de TestFlight-app.
6. **Externe testers** (optioneel, na een korte beta-review van Apple): maak
   een externe groep of deel een publieke link.

## Testinformatie (tabblad TestFlight, eenmalig)

| Veld | Waarde |
|---|---|
| Beta-appbeschrijving | Memo! is een memoryspel voor kinderen en het gezin: draai de kaartjes om en vind de paren, aan één toestel, solo tegen de computer of tegen de klok. Geen reclame, geen accounts, alles blijft op het toestel. |
| Feedback-e-mail | jelle@pivo7.be |
| Contactgegevens beta-review | Jelle Wauters · jelle@pivo7.be |
| Aanmelden vereist? | Nee |

## "Wat te testen" (per build in te vullen)

> Eerste build van Memo! Alles mag stuk, maar kijk vooral naar:
>
> - **Een heel potje** tegen elkaar aan één toestel: klopt de beurtwissel,
>   en mag je na een paar meteen nog een keer?
> - **Solo tegen alle drie de tegenstanders**: voelt Dommel makkelijk en
>   Professor Punt moeilijk-maar-eerlijk?
> - **Tegen de klok**: loopt de tijd goed en wordt je beste tijd bewaard?
> - **Als gast spelen** en **de rondleiding** bij het eerste potje.
> - **De Gezinsversie kopen** (gratis in TestFlight): lukt de ouder-poort, en
>   ontgrendelen Tegen de klok, thema's, statistieken en de extra
>   tegenstanders meteen?
> - **Taal**: zet het toestel eens op Engels of Frans — is álles vertaald?
> - **Onderbreken**: sluit de app midden in een potje af en open opnieuw —
>   gaat het spel verder waar het was?
> - **De drie bordgroottes** en de trofeeënkast na een paar potjes.
>
> Feedback graag via de TestFlight-app (schermafbeelding + opmerking) of
> naar jelle@pivo7.be.

## Goed om te weten tijdens het testen

- **Aankopen in TestFlight zijn gratis** en gebruiken de sandbox; "Eerder
  gekocht? Zet terug" werkt daar ook. Het product moet wél eerst in App Store
  Connect bestaan (stap 2), anders blijft de prijs op "…" staan.
- **Volgende build uploaden**: verhoog `CURRENT_PROJECT_VERSION` in
  project.yml (6 → 7), draai `xcodegen generate`, archiveer en upload
  opnieuw.
  Testers krijgen de update automatisch.
- De **privacyverklaring-URL** is voor TestFlight nog niet verplicht, wel voor
  de echte review — regel die dus ergens tijdens de testronde
  (inhoud: [privacyverklaring.md](privacyverklaring.md)).
