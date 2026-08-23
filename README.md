# Memo!

Een memoryspel voor kinderen, in dezelfde speelgoedstijl als
[Dobbel](https://github.com/PIVO7/Dobbel) en
[Vier op een rij](https://github.com/PIVO7/VierOpEenRij).

Draai twee kaartjes om en vind de paren. Speel met z'n tweeën aan één
toestel of solo tegen Dommel, Robbie of Professor Punt — drie
tegenstanders met een écht geheugen: ze onthouden (en vergeten!) kaarten
zoals een mens dat doet, in plaats van stiekem onder de kaartjes te
kijken.

- SwiftUI, Swift 6, iOS 17+
- Drie bordgroottes (6, 8 of 12 paren)
- Profielen met statistieken, winreeks en beste vangst
- Eén gezinsdeelbare aankoop (Gezinsversie) ontgrendelt alle
  tegenstanders, kleurenthema's en statistieken, achter een ouder-poort
- Toegankelijk: VoiceOver, Verminder beweging en Onderscheid zonder kleur

## Bouwen

Het Xcode-project wordt gegenereerd met [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```
xcodegen generate
open Memo.xcodeproj
```

`project.yml` is de bron van waarheid; het `.xcodeproj` staat gewoon mee
in het archief zodat klonen zonder XcodeGen ook werkt.
