'use strict';

import { environment } from '../../environments/environment';

angular.module('ownerDetails')
    .controller('OwnerDetailsController', ['$http', '$stateParams', function ($http, $stateParams) {
        var self = this;

        $http.get(environment.SPRING_CLOUD_GATEWAY_URL+'/api/customer/owners/' + $stateParams.ownerId).then(function (resp) {
            self.owner = resp.data;
        });
    }]);
