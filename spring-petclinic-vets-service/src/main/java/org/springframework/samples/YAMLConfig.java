package org.springframework.samples;

import org.springframework.context.annotation.Configuration;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.boot.context.properties.ConfigurationProperties;

import org.springframework.context.annotation.Bean;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;

//import com.azure.spring.cloud.autoconfigure.keyvault.secrets.AzureKeyVaultSecretAutoConfiguration;

@Configuration
@EnableConfigurationProperties
@ConfigurationProperties
public class YAMLConfig {
 
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

    public String getKvSecretEndpoint() {
        return kvSecretEndpoint;
    }

    public String getKvSecretPropertySourcesEndpoint() {
        return kvSecretPropertySourcesEndpoint;
    }

    public String getUrl() {
        return url;
    }

    public String getCacheName() {
        return cacheName;
    }

    public String getSqlInitMode() {
        return sqlInitMode;
    }

    public String getSqlDataSourceInitMode() {
        return sqlDataSourceInitMode;
    }

    public String getJpaHibernateDdlAuto() {
        return jpaHibernateDdlAuto;
    }

    public String getLogLevelSpring() {
        return logLevelSpring;
    }

    public void setKvSecretEndpoint(String kvSecretEndpoint) {
        this.kvSecretEndpoint = kvSecretEndpoint;
    }

    public void setKvSecretPropertySourcesEndpoint(String kvSecretPropertySourcesEndpoint) {
        this.kvSecretPropertySourcesEndpoint = kvSecretPropertySourcesEndpoint;
    }

    public void setUrl(String url) {
        this.url = url;
    }

    public void setCacheName(String cacheName) {
        this.cacheName = cacheName;
    }

    public void setSqlInitMode(String sqlInitMode) {
        this.sqlInitMode = sqlInitMode;
    }

    public void setSqlDataSourceInitMode(String sqlDataSourceInitMode) {
        this.sqlDataSourceInitMode = sqlDataSourceInitMode;
    }

    public void setJpaHibernateDdlAuto(String jpaHibernateDdlAuto) {
        this.jpaHibernateDdlAuto = jpaHibernateDdlAuto;
    }

    public void setLogLevelSpring(String logLevelSpring) {
        this.logLevelSpring = logLevelSpring;
    }
 
}