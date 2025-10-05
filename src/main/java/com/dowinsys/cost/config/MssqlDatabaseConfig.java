package com.dowinsys.cost.config;

import javax.sql.DataSource;

import org.apache.ibatis.session.SqlSessionFactory;
import org.mybatis.spring.SqlSessionFactoryBean;
import org.mybatis.spring.SqlSessionTemplate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;
import org.springframework.jdbc.datasource.DataSourceTransactionManager;

import com.dowinsys.cost.common.CamelMap;
import com.zaxxer.hikari.HikariDataSource;

@Configuration
public class MssqlDatabaseConfig {

	
	@Value("${spring.datasource.driver-class-name}")
    private String driverClassName;

    @Value("${spring.datasource.url}")
    private String url;

    @Value("${spring.datasource.username}")
    private String username;

    @Value("${spring.datasource.password}")
    private String password;
    
    @Value("${mybatis.mapper-locations}")
    private String mapperLocations;
    
    @Value("${spring.datasource.hikari.minimum-idle}")
    private int minimumIdle;
    
    @Value("${spring.datasource.hikari.maximum-pool-size}")
    private int maximumPoolSize;
    
    @Value("${spring.datasource.hikari.idle-timeout}")
    private long idleTimeout;
    
    @Value("${spring.datasource.hikari.max-lifetime}")
    private long maxLifetime;
    
    @Value("${spring.datasource.hikari.connection-timeout}")
    private long connectionTimeout;
    
    @Value("${spring.datasource.hikari.keepalive-time}")
    private long keepaliveTime;
    
//    @Bean
//    public DataSource dataSource() {
//        return DataSourceBuilder.create()
//            .driverClassName(driverClassName)
//            .url(url)
//            .username(username)
//            .password(password)
//            .build();
//    }
    
    @Bean
    public DataSource dataSource() {
        HikariDataSource dataSource = new HikariDataSource();
        dataSource.setDriverClassName(driverClassName);
        dataSource.setJdbcUrl(url);
        dataSource.setUsername(username);
        dataSource.setPassword(password);

        // Hikari 설정 적용
        dataSource.setMaximumPoolSize(maximumPoolSize);
        dataSource.setMinimumIdle(minimumIdle);
        dataSource.setIdleTimeout(idleTimeout);
        dataSource.setMaxLifetime(maxLifetime);
        dataSource.setConnectionTimeout(connectionTimeout);
        dataSource.setKeepaliveTime(keepaliveTime);

        return dataSource;
    }
    
    @Bean
    public SqlSessionFactory sqlSessionFactory(DataSource dataSource) throws Exception {
        SqlSessionFactoryBean sessionFactory = new SqlSessionFactoryBean();
        sessionFactory.setDataSource(dataSource);
        
        org.apache.ibatis.session.Configuration configuration = new org.apache.ibatis.session.Configuration();
        configuration.getTypeAliasRegistry().registerAlias("CamelMap", CamelMap.class); // 별칭 등록 DB컬럼명을 Camel Case로 변경 필요시 사용
        configuration.setMapUnderscoreToCamelCase(true);
        configuration.setCallSettersOnNulls(true);
        configuration.setJdbcTypeForNull(org.apache.ibatis.type.JdbcType.NULL);
        
        sessionFactory.setConfiguration(configuration);
        
        sessionFactory.setMapperLocations(
            new PathMatchingResourcePatternResolver().getResources(mapperLocations)
        );
        return sessionFactory.getObject();
    }

    @Bean
    public SqlSessionTemplate sqlSessionTemplate(SqlSessionFactory sqlSessionFactory) {
        return new SqlSessionTemplate(sqlSessionFactory);
    }

    @Bean
    public DataSourceTransactionManager transactionManager(DataSource dataSource) {
        return new DataSourceTransactionManager(dataSource);
    }
}
