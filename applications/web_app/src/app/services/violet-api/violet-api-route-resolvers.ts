import { ResolveFn } from '@angular/router';
import { inject } from '@angular/core';
import { map } from 'rxjs/operators';
import { VioletApi } from './violet-api';
import { MediaCardVm } from '../../components/media-browser-page/media-browser-page';
import { environment } from '../../../environments/environment';

export const moviesCardsResolver: ResolveFn<readonly MediaCardVm[]> = () => {
    const media = inject(VioletApi);

    return media.getMovies().pipe(
        map(movies =>
            movies.map(movie => ({
                id: movie.id,
                title: movie.title,
                subtitle: movie.year ? `${movie.year}` : undefined,
                imageSrc: `${environment.imagesBaseUrl}/${movie.id}/poster.jpg`,
                routerLink: ['/browse/movies', movie.id] as const,
            }))
        )
    );
};

export const tvSeriesCardsResolver: ResolveFn<readonly MediaCardVm[]> = () => {
    const media = inject(VioletApi);

    return media.getSeries().pipe(
        map(series =>
            series.map(item => ({
                id: item.id,
                title: item.title,
                subtitle: item.year ? `${item.year}` : undefined,
                imageSrc: `${environment.imagesBaseUrl}/${item.id}/poster.jpg`,
                routerLink: ['/browse/tv', item.slug] as const,
            }))
        )
    );
};

export const seasonsCardsResolver: ResolveFn<readonly MediaCardVm[]> = (route) => {
    const media = inject(VioletApi);
    const seriesSlug = route.paramMap.get('seriesSlug')!;

    return media.getSeriesSeasons(seriesSlug).pipe(
        map(seasons =>
            seasons.map(season => ({
                id: season.id,
                title: season.title,
                imageSrc: `${environment.imagesBaseUrl}/${season.id}/poster.jpg`,
                routerLink: ['/browse/tv', seriesSlug, season.slug] as const,
            }))
        )
    );
};

export const episodesCardsResolver: ResolveFn<readonly MediaCardVm[]> = (route) => {
    const media = inject(VioletApi);
    const seriesSlug = route.paramMap.get('seriesSlug')!;
    const seasonSlug = route.paramMap.get('seasonSlug')!;

    return media.getSeriesSeasonEpisodes(seriesSlug, seasonSlug).pipe(
        map(episodes =>
            episodes.map(episode => ({
                id: episode.id,
                title: episode.title,
                subtitle: `Episode ${episode.episode_number}`,
                imageSrc: `${environment.imagesBaseUrl}/${episode.id}/still.jpg`,
                routerLink: ['/browse/tv', seriesSlug, seasonSlug, episode.id] as const,
            }))
        )
    );
};