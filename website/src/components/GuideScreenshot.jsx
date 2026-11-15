import React, {useEffect, useRef, useState} from 'react';
import useBaseUrl from '@docusaurus/useBaseUrl';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import {layoutGuideCallouts} from './guideCallouts.mjs';
import screenshots from '../data/screenshotRevision.json';

/** The original image stays unobstructed; labels live in reserved outside gutters. */
function AnnotatedImage({image, alt, steps, start}) {
  const frameRef = useRef(null);
  const imageRef = useRef(null);
  const [geometry, setGeometry] = useState(null);
  const positioned = steps.filter(step => Number.isFinite(step.x) && Number.isFinite(step.y));
  const lanes = Math.max(positioned.filter(step => step.x <= 50).length,
    positioned.filter(step => step.x > 50).length);
  useEffect(() => {
    const measure = () => {
      const frame = frameRef.current?.getBoundingClientRect();
      const photo = imageRef.current?.getBoundingClientRect();
      if (!frame?.width || !photo?.width || !photo?.height) return;
      const next = {frame: {width: frame.width, height: frame.height},
        image: {x: photo.left - frame.left, y: photo.top - frame.top,
          width: photo.width, height: photo.height}};
      setGeometry(previous => JSON.stringify(previous) === JSON.stringify(next) ? previous : next);
    };
    const observer = new ResizeObserver(measure);
    observer.observe(frameRef.current);
    observer.observe(imageRef.current);
    imageRef.current.addEventListener('load', measure);
    measure();
    const photo = imageRef.current;
    return () => {observer.disconnect(); photo.removeEventListener('load', measure);};
  }, [image]);
  const callouts = geometry ? layoutGuideCallouts(steps, geometry.frame, geometry.image, start) : [];
  return <span ref={frameRef} className="guide-annotated-frame" style={{minHeight: `${Math.max(52, lanes * 32 + 12)}px`}}>
    <img ref={imageRef} src={image} alt={alt} loading="lazy" />
    {geometry && <svg className="guide-screenshot-pointers" viewBox={`0 0 ${geometry.frame.width} ${geometry.frame.height}`} aria-hidden="true">
      {callouts.map(item => {
        const path = `M ${item.x} ${item.y} L ${item.targetX} ${item.targetY}`;
        return <g key={item.number}>
          <path className="guide-screenshot-pointer" d={path} />
        </g>;
      })}
    </svg>}
    {callouts.map(item => <span key={item.number} className="guide-screenshot-marker" aria-hidden="true"
      style={{left: item.x, top: item.y}}>{item.number}</span>)}
  </span>;
}

/** Native screenshot plus accessible numbered instructions; coordinates are percentages. */
export default function GuideScreenshot({src, alt, steps = [], caption, start = 1}) {
  const image = `${useBaseUrl(src)}?v=${screenshots.revision}`;
  const dialog = useRef(null);
  const [actualSize, setActualSize] = useState(false);
  const {i18n} = useDocusaurusContext();
  const close = {en: 'Close image', ro: 'Închide imaginea', ru: 'Закрыть изображение'}[i18n.currentLocale] || 'Close image';
  const zoom = {en: ['Actual size', 'Fit to screen'], ro: ['Mărime originală', 'Încadrează pe ecran'], ru: ['Исходный размер', 'По размеру экрана']}[i18n.currentLocale] || ['Actual size', 'Fit to screen'];
  const picture = () => <AnnotatedImage image={image} alt={alt} steps={steps} start={start} />;
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
