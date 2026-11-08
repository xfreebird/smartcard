import React, {useRef, useState} from 'react';
import useBaseUrl from '@docusaurus/useBaseUrl';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';

/** Native screenshot plus accessible numbered instructions; coordinates are percentages. */
export default function GuideScreenshot({src, alt, steps = [], caption, start = 1}) {
  const image = useBaseUrl(src);
  const dialog = useRef(null);
  const [actualSize, setActualSize] = useState(false);
  const {i18n} = useDocusaurusContext();
  const close = {en: 'Close image', ro: 'Închide imaginea', ru: 'Закрыть изображение'}[i18n.currentLocale] || 'Close image';
  const zoom = {en: ['Actual size', 'Fit to screen'], ro: ['Mărime originală', 'Încadrează pe ecran'], ru: ['Исходный размер', 'По размеру экрана']}[i18n.currentLocale] || ['Actual size', 'Fit to screen'];
  const picture = () => <>
    <img src={image} alt={alt} loading="lazy" />
    {steps.map((step, index) => Number.isFinite(step.x) && Number.isFinite(step.y) &&
      <span key={index} className="guide-screenshot-marker" aria-hidden="true"
        style={{left: `clamp(16px, ${step.x}%, calc(100% - 16px))`, top: `clamp(16px, ${step.y}%, calc(100% - 16px))`}}>{index + start}</span>)}
  </>;
  return <figure className="guide-screenshot">
    <button type="button" className="guide-screenshot-image" onClick={() => {setActualSize(false); dialog.current?.showModal();}} aria-label={alt} aria-haspopup="dialog">
      {picture()}
    </button>
    <figcaption>{caption && <p>{caption}</p>}
      <ol start={start}>{steps.map((step, index) => <li key={index}>{step.text}</li>)}</ol>
    </figcaption>
    <dialog ref={dialog} className={`guide-screenshot-dialog${actualSize ? ' guide-screenshot-actual-size' : ''}`} aria-label={alt} onClick={event => {if (event.target === event.currentTarget) event.currentTarget.close();}}>
      <div className="guide-screenshot-tools">
        <button type="button" onClick={() => setActualSize(value => !value)}>{zoom[actualSize ? 1 : 0]}</button>
        <button type="button" className="guide-screenshot-close" onClick={() => dialog.current?.close()} aria-label={close}>×</button>
      </div>
      <div className="guide-screenshot-image">{picture()}</div>
    </dialog>
  </figure>;
}
