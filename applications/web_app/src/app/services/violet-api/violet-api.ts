import { HttpClient } from '@angular/common/http';
import { inject, Injectable } from '@angular/core';
import { environment } from '../../../environments/environment';

export interface MovieResponse {
  readonly title: string;
  readonly id: string;
  readonly year: number;
  readonly slug: string;
}

export interface TVSeriesResponse {
  readonly title: string;
  readonly id: string;
  readonly year: number;
  readonly slug: string;
}

export interface TVSeriesSeasonResponse {
  readonly title: string;
  readonly id: string;
  readonly season_number: number;
  readonly slug: string;
}

export interface TVSeriesSeasonEpisodeResponse {
  readonly title: string;
  readonly id: string;
  readonly episode_number: number;
}

@Injectable({
  providedIn: 'root',
})
export class VioletApi {
  private http = inject(HttpClient);

  getMovies() {
    return this.http.get<MovieResponse[]>(`${environment.apiBaseUrl}/movies`);
  }

  getSeries() {
    return this.http.get<TVSeriesResponse[]>(`${environment.apiBaseUrl}/tv/series`);
  }

  getSeriesSeasons(seriesSlug: string) {
    return this.http.get<TVSeriesSeasonResponse[]>(
      `${environment.apiBaseUrl}/tv/series/${seriesSlug}`,
    );
  }

  getSeriesSeasonEpisodes(seriesSlug: string, seasonSlug: string) {
    return this.http.get<TVSeriesSeasonEpisodeResponse[]>(
      `${environment.apiBaseUrl}/tv/series/${seriesSlug}/season/${seasonSlug}`,
    );
  }
}
