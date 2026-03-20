export interface EnvironmentConfig {
    /**
     * The API base URL.
     * 
     * @example https://abcdefghijkl.cloudfront.net/api
     */
    readonly apiBaseUrl: string

    /**
     * The images base URL.
     * 
     * @example https://abcdefghijkl.cloudfront.net/images
     */
    readonly imagesBaseUrl: string

    /**
     * The output base URL.
     * 
     * @example https://abcdefghijkl.cloudfront.net/output
     */
    readonly outputBaseUrl: string

    /**
     * Production environment (build optimisations).
     */
    readonly production: boolean
}
