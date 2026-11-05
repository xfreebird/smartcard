---
hide_table_of_contents: true
title: Recommended devices
description: Choose a USB adapter for your eSemnBun smart-card reader, with Apple and Amazon shopping links.
---

import DeviceVisual from '@site/src/components/DeviceVisual';

<div className="devices-guide">
<header className="devices-hero">
<div className="devices-hero-copy">
<p className="devices-eyebrow">eSemnBun / Recommended devices</p>

# A small adapter. A complete connection.

Connect your USB-A smart-card reader with an adapter that matches your phone, tablet or computer. For eSemnBun on iPhone and iPad, use **iOS / iPadOS 17 or later**.

<nav className="devices-jump" aria-label="Choose your connection"><a href="#usb-c">USB-C devices <span aria-hidden="true">↘</span></a><a href="#lightning">Lightning devices <span aria-hidden="true">↘</span></a></nav>
</div>
<div className="devices-hero-art" aria-hidden="true">
<DeviceVisual image="/img/devices/usb-c-apple.jpg" alt=""/>
<span className="devices-hero-label">USB-C → USB-A</span>
</div>
</header>
<div className="devices-choice-grid">
<section className="devices-choice" id="usb-c">
<span className="devices-number">01</span>

## USB-C devices

<div className="devices-flow">Device → USB-C to USB-A adapter → USB-A card reader</div>

Choose an adapter with a USB-C plug, USB-A socket and USB data support. Android devices also need USB host / OTG support.

<div className="devices-products">
<article className="devices-product"><div className="devices-product-photo"><DeviceVisual image="/img/devices/usb-c-apple.jpg" alt="Apple USB-C to USB Adapter"/></div><h3>Apple USB-C to USB Adapter</h3><div className="devices-product-links"><a href="https://altex.ro/adaptor-usb-c-la-usb-apple-mw5l3zm-a-alb/cpd/CABMW5L3ZMA/">Altex.ro ↗</a><a href="https://xstore.md/apple/accesorii/apple-usb-c-to-usb-adapter-mj1m2">Xstore.md ↗</a><a href="https://atehno.md/products/apple-usbc-to-usb-adapter-9857901962873">ATEHNO.md ↗</a><a href="https://www.apple.com/shop/product/mw5l3am/a/usb-c-to-usb-adapter">View at Apple <span aria-hidden="true">↗</span></a></div></article>
<article className="devices-product"><div className="devices-product-photo"><DeviceVisual image="/img/devices/usb-c-anker.jpg" alt="Anker USB-C to USB-A · 2-pack"/></div><h3>Anker USB-C to USB-A · 2-pack</h3><div className="devices-product-links"><a href="https://www.amazon.com/dp/B08HZ6PS61">View at Amazon <span aria-hidden="true">↗</span></a></div></article>
</div>

More USB-C to USB-A options in Moldova: [Baseus OTG at HopShop](https://hopshop.md/products/baseus-otg-adaptor-mini-type-c-to-usb-a-31-black) · [Cablexpert OTG at Moll Market](https://moll-market.md/ro/adaptor-usb-cablexpert-a-otg-cmaf3-01-usb-type-a-f-usb-type-c-m-0-2m-negru).


Romania: [UGREEN USB-C to USB-A OTG at eMAG](https://www.emag.ro/adaptor-otg-ugreen-usb-c-tata-usb-a-mama-5gb-s-0-15-m-negru-34358/pd/D692MKYBM/).

</section>
<section className="devices-choice" id="lightning">
<span className="devices-number">02</span>

## Lightning iPhone and iPad

<div className="devices-flow">Device → Lightning to USB 3 Camera Adapter → USB-A card reader</div>

The camera adapter provides the USB-A socket for the reader. Its extra Lightning port accepts power if the device reports that the accessory needs more power; a separate power adapter is not automatically required. See [Apple’s USB accessory guidance](https://support.apple.com/en-us/111811).

<div className="devices-products">
<article className="devices-product"><div className="devices-product-photo"><DeviceVisual image="/img/devices/lightning-camera.jpg" alt="Apple Lightning to USB 3 Camera Adapter"/></div><h3>Apple Lightning to USB 3 Camera Adapter</h3><div className="devices-product-links"><a href="https://istyle.ro/products/adaptor-apple-pentru-camera-de-la-lightning-la-usb-3-0">iSTYLE.ro ↗</a><a href="https://www.apple.com/shop/product/mx5j3am/a/lightning-to-usb-3-camera-adapter">View at Apple <span aria-hidden="true">↗</span></a><a href="https://www.amazon.com/dp/B01F7KJDIM">View at Amazon <span aria-hidden="true">↗</span></a></div></article>
</div>
</section>
</div>
<section className="devices-direction">
<div className="devices-direction-photo"><DeviceVisual image="/img/devices/lightning-usbc.jpg" alt="Apple USB-C to Lightning Adapter"/></div>
<div>
<p className="devices-eyebrow">Check the connector</p>

## USB-C to Lightning adapter + USB-C to USB-A adapter

**Check the connector direction before buying this combination.** Apple’s [USB-C to Lightning Adapter](https://www.apple.com/shop/product/muqx3am/a/usb-c-to-lightning-adapter) has a USB-C plug and a Lightning socket. It connects Lightning accessories to USB-C devices; it does not give a Lightning iPhone a USB-C socket. These two Apple adapters therefore cannot connect directly together.

A third-party adapter with a Lightning plug and USB-C socket would need explicit USB host/accessory support. Charging or cable-sync support alone does not establish card-reader compatibility. This two-adapter combination has not been verified here; choose the Lightning camera adapter above for a Lightning device. [Apple explains its adapter’s direction and functions](https://support.apple.com/en-au/109044).

</div></section>
<section className="devices-reader">
<div className="devices-reader-copy">
<p className="devices-eyebrow">Your card. Your phone.</p>

## The card reader

The **bit4id miniLector POCKET EVO** is the reference reader used by this project. The shopping examples above are adapter choices based on their published connectors and USB functions, not a claim that every combination has been tested with eSemnBun. A computer with USB-A can connect the reader directly.

[Download eSemnBun](/downloads) · [Connect your reader and start signing](/docs/start)

</div>
<figure className="devices-app-preview"><DeviceVisual image="/img/landing/iphone/ready-light.png" alt="eSemnBun — demo"/><figcaption>An eSemnBun demo screen; no real identity data.</figcaption></figure>
</section>
<footer className="devices-notes">

Retail links are not affiliate links. Check the model, seller and delivery region; prices and availability vary.

Product photography: Apple and Anker.

</footer>
</div>
