/*
 * Copyright 2002-2017 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.springframework.samples.petclinic.vets.web;

import lombok.RequiredArgsConstructor;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.samples.YAMLConfig;
import org.springframework.samples.petclinic.vets.model.Vet;
import org.springframework.samples.petclinic.vets.model.VetRepository;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * @author Juergen Hoeller
 * @author Mark Fisher
 * @author Ken Krebs
 * @author Arjen Poutsma
 * @author Maciej Szarlinski
 */
@RequestMapping("/vets")
@RestController
@RequiredArgsConstructor
class VetResource {

    private final VetRepository vetRepository;

    @Autowired
    private YAMLConfig myConfig;
	
	@Value("${spring.cloud.azure.keyvault.secret.endpoint}")
    private String kvSecretEndpoint;

	@Value("${spring.cloud.azure.keyvault.secret.property-sources[0].endpoint}")
    private String kvSecretPropertySourcesEndpoint;

	@Value("${spring.datasource.url}")
    private String url;

	@Value("${spring.cache.cache-names}")
    private String cacheName;
	
	@Value("${spring.sql.init.mode}")
    private String sqlInitMode;

	@Value("${spring.sql.datasource.initialization-mode}")
	private String sqlDataSourceInitMode;

	@Value("${spring.jpa.hibernate.ddl-auto}")
	private String jpaHibernateDdlAuto;

	@Value("${logging.level.org.springframework}")
    private String logLevelSpring;
    
    @GetMapping
    public List<Vet> showResourcesVetList() {

		System.out.println("Spring log level from config file: " + logLevelSpring);

		System.out.println("sqlDataSourceInitMode from config file: " + sqlDataSourceInitMode);
		System.out.println("jpaHibernateDdlAuto from config file: " + jpaHibernateDdlAuto);

		System.out.println("cache name from config file: " + cacheName);
		System.out.println("SQL Init mode from config file: " + sqlInitMode);

        System.out.println("kvSecretEndpoint from config file: " + kvSecretEndpoint);
		System.out.println("kvSecretPropertySourcesEndpoint from config file: " + kvSecretPropertySourcesEndpoint);
		System.out.println("JDBC URL from config file: " + url);
		
        return vetRepository.findAll();
    }
}
