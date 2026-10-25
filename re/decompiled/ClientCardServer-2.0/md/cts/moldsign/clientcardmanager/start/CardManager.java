/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  md.ghesar.Intern
 */
package md.cts.moldsign.clientcardmanager.start;

import cargo.DartBoss;
import cargo.DartCallback;
import java.util.HashMap;
import javax.swing.SwingUtilities;
import md.cts.moldsign.clientcardmanager.ui.main.GnomeCardTray;
import md.cts.moldsign.clientcardmanager.ui.main.MotoCardTray;
import md.cts.pkcs11.cards.observers.CardActionObserver;
import md.cts.pkcs11.cards.observers.CardReaderEvent;
import md.ghesar.Intern;
import svelte.Coco;

public final class CardManager
implements CardActionObserver {
    private final HashMap<Long, GnomeCardTray> cardTrayList = new HashMap();
    private final HashMap<Long, MotoCardTray> cardMotoTrayList = new HashMap();

    private static void startRenewal() {
        DartBoss.startCheckCertificate(code -> {
            if (code == DartCallback.Code.OK) {
                SwingUtilities.invokeLater(Coco::displayOneByOne);
            }
        });
    }

    @Override
    public void onCardAction(CardReaderEvent event) {
        SwingUtilities.invokeLater(() -> this.doAction(event));
    }

    private void doAction(CardReaderEvent event) {
        CardReaderEvent.Action action = event.getAction();
        Long slotGlobalId = event.getSlotGlobalId();
        if (action == CardReaderEvent.Action.INSERTED) {
            SwingUtilities.invokeLater(CardManager::startRenewal);
            if (Intern.useClassicSystemTray) {
                MotoCardTray tray = new MotoCardTray();
                this.cardMotoTrayList.put(slotGlobalId, tray);
                tray.showTray(slotGlobalId);
            } else {
                GnomeCardTray tray = new GnomeCardTray();
                this.cardTrayList.put(slotGlobalId, tray);
                tray.showTray(slotGlobalId);
            }
        } else if (action == CardReaderEvent.Action.REMOVED) {
            if (Intern.useClassicSystemTray) {
                MotoCardTray tray = this.cardMotoTrayList.get(slotGlobalId);
                if (tray != null) {
                    tray.closeTray();
                    this.cardMotoTrayList.remove(slotGlobalId);
                }
            } else {
                GnomeCardTray tray = this.cardTrayList.get(slotGlobalId);
                if (tray != null) {
                    tray.closeTray();
                    this.cardTrayList.remove(slotGlobalId);
                }
            }
        }
    }
}

