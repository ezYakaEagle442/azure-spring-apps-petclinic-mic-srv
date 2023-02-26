// https://angular.io/guide/build
// https://itnext.io/how-to-use-system-environment-variables-process-env-in-angular-application-b9e7104dcc98
export const environment = {
    production: false,
    envVar: {
      SPRING_CLOUD_GATEWAY_URL: '$SPRING_CLOUD_GATEWAY_URL',
      LOG_LEVEL: 'info',
      version: 0
    }
  };