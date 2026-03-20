import { Routes } from '@angular/router';
import { PlayerPageComponent } from './components/vidstack-player-layout/vidstack-player-layout';
import { MediaBrowserPage } from './components/media-browser-page/media-browser-page';
import {
  episodesCardsResolver,
  moviesCardsResolver,
  seasonsCardsResolver,
  tvSeriesCardsResolver,
} from './services/violet-api/violet-api-route-resolvers';

export const routes: Routes = [
  { path: '', redirectTo: 'browse/tv', pathMatch: 'full' },
  { path: 'browse', redirectTo: 'browse/tv', pathMatch: 'full' },
  {
    path: 'browse/movies',
    component: MediaBrowserPage,
    resolve: { cards: moviesCardsResolver },
  },
  {
    path: 'browse/tv',
    component: MediaBrowserPage,
    resolve: { cards: tvSeriesCardsResolver },
  },
  {
    path: 'browse/tv/:seriesSlug',
    component: MediaBrowserPage,
    resolve: { cards: seasonsCardsResolver },
  },
  {
    path: 'browse/tv/:seriesSlug/:seasonSlug',
    component: MediaBrowserPage,
    resolve: { cards: episodesCardsResolver },
  },

  {
    path: 'browse/movies/:mediaId',
    component: PlayerPageComponent,
  },
  {
    path: 'browse/tv/:seriesSlug/:seasonSlug/:mediaId',
    component: PlayerPageComponent,
  },
];
