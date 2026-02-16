## Sempol – prototipo iPad (SwiftUI)

Questa cartella contiene il codice SwiftUI del prototipo di **Sempol** per iPad in modalità **portrait**.

### Architettura

- `SempolApp.swift` – entry point dell'app.
- `RootView.swift` – contiene il `NavigationStack`.
- `HomeView.swift` – gallery di card (per ora la card centrale apre il ritratto Elfo).
- `ElfPlayView.swift` – schermata interattiva con il ritratto Elfo e i tasti per la base musicale.
- `AudioManager.swift` – gestione della base sonora in loop e dei suoni delle parti del ritratto.

### Suoni richiesti nel bundle Xcode

Nella target iOS di Xcode aggiungi (come `Resource` nel main bundle) i seguenti file `.mp3`:

- `suono-elfo-bocca.mp3`
- `suono-elfo-capelli.mp3`
- `suono-elfo-naso.mp3`
- `suono-elfo-occhio-dx.mp3`
- `suono-elfo-occhio-sx.mp3`
- `suono-elfo-orecchio-dx.mp3`
- `suono-elfo-orecchio-sx.mp3`
- `Downtown-base.mp3` – base musicale da riprodurre in loop infinito.

I nomi devono coincidere esattamente con quelli sopra (senza errori di maiuscole/minuscole).

### Come integrare in Xcode (iPad only, portrait only)

1. In Xcode crea un nuovo progetto **iOS App** (SwiftUI, Swift) chiamato `Sempol`.
2. Nella sezione **Deployment Info**:
   - in **Devices** seleziona solo **iPad**,
   - in **Device Orientation** lascia attiva solo **Portrait**.
3. Trascina i file di questa cartella (`SempolApp`) dentro il gruppo sorgenti del progetto Xcode, assicurandoti di selezionare la target iOS.
4. Aggiungi i file audio indicati sopra al target (flag *Add to targets* attivo).
5. Se vuoi usare le illustrazioni da Figma, esporta gli asset in PNG e aggiungili come `Image Set` nel catalogo asset, aggiornando poi le `Image(...)` in SwiftUI.
6. Collega il tuo iPad 13" (5ª generazione), selezionalo come destinazione di build e premi **Run** per lanciare il prototipo.

