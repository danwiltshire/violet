import { Component } from '@angular/core';
import { RouterLink, RouterLinkActive } from '@angular/router';

@Component({
  selector: 'app-media-browser-header',
  imports: [RouterLink, RouterLinkActive],
  templateUrl: './media-browser-header.html',
  styleUrl: './media-browser-header.css',
})
export class MediaBrowserHeader {}
