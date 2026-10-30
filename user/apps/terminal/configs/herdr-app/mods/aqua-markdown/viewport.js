/** @typedef {{x: number, y: number}} Point */
/** @typedef {{width: number, height: number}} Size */

export class DiagramViewport {
  constructor() {
    this.size = { width: 600, height: 500 };
    this.content = { width: 0, height: 0 };
    this.pan = { x: 0, y: 0 };
    this.fit = true;
    this.zoom = 1;
  }

  scale() {
    return this.fit ? Math.min(1, Math.max(1, this.size.width - 20) / Math.max(1, this.content.width), Math.max(1, this.size.height - 20) / Math.max(1, this.content.height)) : this.zoom;
  }

  position() {
    const scale = this.scale(), width = this.content.width * scale, height = this.content.height * scale;
    const visible = Math.min(32, width / 2, height / 2, this.size.width / 2, this.size.height / 2);
    return {
      x: Math.max(visible - width, Math.min(this.size.width - visible, (this.size.width - width) / 2 + this.pan.x)),
      y: Math.max(visible - height, Math.min(this.size.height - visible, (this.size.height - height) / 2 + this.pan.y)),
    };
  }

  /** @param {number} x @param {number} y */
  move(x, y) {
    this.pan.x += x;
    this.pan.y += y;
    const position = this.position(), scale = this.scale();
    this.pan = { x: position.x - (this.size.width - this.content.width * scale) / 2, y: position.y - (this.size.height - this.content.height * scale) / 2 };
  }

  /** @param {boolean} [fit] */
  reset(fit = true) {
    this.pan = { x: 0, y: 0 };
    this.fit = fit;
    this.zoom = 1;
  }

  centre() { this.pan = { x: 0, y: 0 }; }

  /** @param {number} multiplier @param {Point} [anchor] */
  changeZoom(multiplier, anchor = { x: this.size.width / 2, y: this.size.height / 2 }) {
    const before = this.scale(), position = this.position();
    this.zoom = Math.max(0.1, Math.min(4, before * multiplier));
    this.fit = false;
    const ratio = this.zoom / before;
    this.pan = {
      x: anchor.x - (anchor.x - position.x) * ratio - (this.size.width - this.content.width * this.zoom) / 2,
      y: anchor.y - (anchor.y - position.y) * ratio - (this.size.height - this.content.height * this.zoom) / 2,
    };
    this.move(0, 0);
  }
}
