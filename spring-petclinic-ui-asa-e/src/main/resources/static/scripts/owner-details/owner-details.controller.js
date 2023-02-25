'use strict';

angular.module('ownerDetails')
    .controller('OwnerDetailsController', ['$http', '$stateParams', function ($http, $stateParams) {
        var self = this;

        $http.get($SPRING_CLOUD_GATEWAY_URL+'/api/customer/owners/' + $stateParams.ownerId).then(function (resp) {
            self.owner = resp.data;
        });
    }]);
