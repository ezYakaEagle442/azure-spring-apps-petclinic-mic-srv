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
package org.springframework.samples.petclinic.vets;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.samples.petclinic.vets.system.VetsProperties;

import java.net.*;
import java.io.BufferedReader;
import java.io.InputStreamReader;

import org.springframework.beans.factory.annotation.Value;
// import org.apache.commons.net.telnet.TelnetClient;

/**
 * @author Maciej Szarlinski
 */
@EnableDiscoveryClient
@SpringBootApplication
@EnableConfigurationProperties(VetsProperties.class)
public class VetsServiceApplication {

	@Value("${spring.datasource.url}")
    private static String url;

	@Value("${spring.cache.cache-names}")
    private static String cacheName;
	
	@Value("${spring.sql.init.mode}")
    private static String sqlInitMode;

	public static void main(String[] args) {
	
		System.out.println("Checking ENV variables ..."+ "\n");
		
		System.out.println("Checking ENV variable AZURE_KEYVAULT_ENDPOINT : |" + System.getenv("AZURE_KEYVAULT_ENDPOINT") + "|\n");

		System.out.println("Checking ENV variable AZURE KV ENDPOINT : |" + System.getenv("ENDPOINT") + "|\n");
		System.out.println("Checking ENV variable AZURE_TENANT_ID : |" + System.getenv("AZURE_TENANT_ID") + "|\n");
		System.out.println("Checking ENV variable AZURE_CLIENT_ID : |" + System.getenv("AZURE_CLIENT_ID") + "|\n");

		System.out.println("JDBC URL from config file: " + url);
		System.out.println("cache name: " + cacheName);
		System.out.println("SQL Init mode: " + sqlInitMode);
		System.out.println("JDBC URL from config file: " + url);
		
		System.out.println("Checking ENV variable SPRING_PROFILES_ACTIVE : |" + System.getenv("SPRING_PROFILES_ACTIVE") + "|\n");
		System.out.println("Checking ENV variable AZURE_KEYVAULT_URI : |" + System.getenv("AZURE_KEYVAULT_URI") + "|\n");

		System.out.println("Checking property azure.keyvault.uri : |" + System.getProperty("azure.keyvault.uri") + "|\n");
		System.out.println("Checking property spring.profiles.active : |" + System.getProperty("spring.profiles.active") + "|\n");

		System.out.println("Checking ENV variable MYSQL_SERVER_FULL_NAME : |" + System.getenv("MYSQL_SERVER_FULL_NAME") + "|\n");
		System.out.println("Checking ENV variable MYSQL_DATABASE_NAME : |" + System.getenv("MYSQL_DATABASE_NAME") + "|\n");
		System.out.println("Checking ENV variable MYSQL_SERVER_ADMIN_LOGIN_NAME : |" + System.getenv("MYSQL_SERVER_ADMIN_LOGIN_NAME") + "|\n");
		System.out.println("Checking ENV variable MYSQL_SERVER_ADMIN_PASSWORD : |" + System.getenv("MYSQL_SERVER_ADMIN_PASSWORD") + "|\n");

        String systemipaddress = "";
        try {
            URL url_name = new URL("http://whatismyip.akamai.com");
            BufferedReader sc = new BufferedReader(new InputStreamReader(url_name.openStream()));
            systemipaddress = sc.readLine().trim();
        }
        catch (Exception e) {
            systemipaddress = "Cannot Execute Properly";
        }
        System.out.println("Public IP Address: " + systemipaddress + "\n");


		// https://github.com/Azure/AKS/blob/2022-03-27/vhd-notes/aks-ubuntu/AKSUbuntu-1804/2022.03.23.txt
		// Telnet & Netcat look installed on the AKS nodes, but not on the App container
		/*
		Runtime runtime = Runtime.getRuntime();
		try {
			Process process =runtime.exec("telnet petcliasc.mysql.database.azure.com 3306");
			System.out.println( "SUCCESSFULLY executed Telnet");
        }
        catch (Exception e) {
			System.err.println( "Cannot Execute Telnet");
			e.printStackTrace();
        }

		try {
			Process process =runtime.exec("nc -vz petcliasc.mysql.database.azure.com 3306");
			System.out.println( "SUCCESSFULLY executed Netcat");
        }
        catch (Exception e) {
			System.err.println("Cannot Execute Netcat");
			e.printStackTrace();
        }
		
		TelnetClient telnetClient = new TelnetClient();
		try {
			// telnetClient.connect("petcliasc.mysql.database.azure.com", 3306);
			telnetClient.connect(System.getenv("MYSQL_SERVER_FULL_NAME"), 3306);
			System.out.println( "SUCCESSFULLY executed TelnetClient");
			telnetClient.disconnect();
        }
        catch (Exception e) {
			System.err.println("Cannot Execute TelnetClient");
			e.printStackTrace();
        }
		*/
		SpringApplication.run(VetsServiceApplication.class, args);
	}
}
