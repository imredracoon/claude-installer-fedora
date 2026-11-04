# Claude Desktop su Fedora, con aggiornamento automatico

Installa **Claude Desktop** su Fedora (x86_64) partendo dalla build Linux ufficiale di Anthropic e lo tiene aggiornato da solo con un timer di systemd.

> Anthropic pubblica Claude Desktop per Linux solo come pacchetto `.deb` per Ubuntu e Debian. Su Fedora l'app non è supportata ufficialmente: funziona, ma per eventuali problemi il supporto Anthropic non aiuta.

## Come funziona

1. **`build-official.sh`** è lo script originale di [dewzor/claude-desktop-fedora](https://github.com/dewzor/claude-desktop-fedora), copiato senza modifiche (commit `f9f3faa`, 22 ottobre 2026). Fa queste cose:
   - scarica solo da `downloads.claude.ai`, il repository ufficiale di Anthropic;
   - verifica la firma dell'indice con la chiave di Anthropic incorporata nello script (fingerprint `31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE`, la stessa pubblicata nella [documentazione ufficiale](https://code.claude.com/docs/en/desktop-linux));
   - controlla lo SHA256 del `.deb` scaricato;
   - reimpacchetta l'app così com'è in un RPM, senza modificarla.
2. **`claude-desktop-autoupdate`** è il nostro script di aggiornamento. Confronta la versione installata con quella pubblicata da Anthropic e, se ce n'è una nuova, costruisce l'RPM e lo installa. Download, verifica e costruzione girano come utente `nobody` (senza privilegi): solo il `dnf install` finale gira come root.
3. **Un timer systemd** lancia l'aggiornamento una volta al giorno, con un ritardo casuale fino a un'ora. Se il computer era spento, recupera al primo avvio. Gira a priorità minima, quindi non rallenta il lavoro.

Il tutto non dipende da repository o pacchetti di terzi: lo script viene copiato in una cartella di sistema e cambia solo quando lo aggiorni tu.

## Installazione

Su un computer Fedora:

```bash
git clone https://github.com/<tuo-utente>/<nome-repo>.git
cd <nome-repo>
sudo bash install.sh
```

Usa `sudo bash install.sh` e non `./install.sh`: se i file sono stati caricati su GitHub dal browser perdono il permesso di esecuzione, e così funziona comunque.

L'installer:
- installa gli strumenti necessari (`rpm-build`, `binutils`, `file`, `xz`, `curl`, `gnupg2`);
- copia gli script in `/usr/local/libexec/claude-desktop/` e `/usr/local/sbin/`;
- crea e attiva il timer;
- fa subito un primo controllo: se Claude non è installato lo scarica (circa 165 MB) e lo installa.

Dopo l'installazione la cartella della repo si può cancellare.

## Comandi utili

```bash
# forzare un controllo adesso
sudo systemctl start claude-desktop-autoupdate.service

# vedere cosa ha fatto l'ultima volta
journalctl -u claude-desktop-autoupdate -n 20

# disattivare gli aggiornamenti automatici
sudo systemctl disable --now claude-desktop-autoupdate.timer
```

Altri comandi:

```bash
# controllare se c'è un aggiornamento senza installarlo
sudo claude-desktop-autoupdate --check

# ricostruire e reinstallare anche se la versione è già l'ultima
sudo claude-desktop-autoupdate --force

# vedere quando è previsto il prossimo controllo
systemctl list-timers | grep claude
```

Dopo un aggiornamento chiudi e riapri Claude per usare la nuova versione.

## Disinstallazione

```bash
# toglie timer e script, Claude resta installato
sudo bash install.sh --uninstall

# toglie anche Claude
sudo dnf remove claude-desktop
```

## Se l'aggiornamento si ferma con un errore

Se nel log compare un errore sulla **firma** o sulla **chiave**, non aggirarlo: significa che qualcosa non torna con l'indice scaricato, oppure che Anthropic ha cambiato chiave o formato del repository. In quel caso:

1. controlla la [documentazione ufficiale](https://code.claude.com/docs/en/desktop-linux) e la repo di [dewzor](https://github.com/dewzor/claude-desktop-fedora) per eventuali novità;
2. se c'è una versione nuova di `build-official.sh`, leggi le modifiche, aggiornala in questa repo e rilancia `sudo bash install.sh`.

## Icona nella barra di GNOME

Fedora non include l'estensione per le icone nella barra. Installa **AppIndicator Support** da [extensions.gnome.org](https://extensions.gnome.org/extension/615/appindicator-support/) o dall'app *Gestore estensioni*, poi esci e rientra nella sessione. Il pacchetto `gnome-shell-extension-appindicator` di Fedora può risultare incompatibile se hai una versione di GNOME più recente di quella per cui è stato compilato.

## Crediti e licenza

- `build-official.sh` è di [dewzor/claude-desktop-fedora](https://github.com/dewzor/claude-desktop-fedora) e dei suoi contributori, distribuito con doppia licenza MIT / Apache-2.0 (vedi `LICENSE-MIT` e `LICENSE-APACHE`).
- Gli altri file di questa repo sono rilasciati con le stesse licenze.
- Claude Desktop è software proprietario di Anthropic e **non** è incluso in questa repo: viene scaricato dai server di Anthropic al momento dell'installazione.
