import { Component, input, signal } from '@angular/core';
import { RouterLink, RouterLinkActive } from '@angular/router';

@Component({
  selector: 'vidstack-player-header',
  imports: [RouterLink],
  templateUrl: './vidstack-player-header.html',
  host: {
    '(document:mousemove)': 'onMouseActivity()',
  },
})
export class VidstackPlayerHeader {
  readonly visible = signal(true);
  readonly mediaTitle = input.required<string>();
  readonly mediaSubtitle = input.required<string>();

  private idleTimeout?: number;

  onMouseActivity() {
    this.visible.set(true);
    this.restartIdleTimer();
  }

  private restartIdleTimer() {
    window.clearTimeout(this.idleTimeout);
    this.idleTimeout = window.setTimeout(() => {
      this.visible.set(false);
    }, 2000);
  }
}
