package com.dowinsys.cost;

import java.io.PrintStream;

import org.apache.poi.sl.usermodel.ObjectMetaData.Application;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@EnableScheduling
@SpringBootApplication
public class DwisCostApplication {
	private static final Logger logger = LoggerFactory.getLogger(Application.class);
	public static void main(String[] args) {
		
		// stdout/stderr → SLF4J로 리디렉션
        System.setOut(new PrintStream(System.out) {
            @Override
            public void println(String s) {
            	for (String line : s.split("\\r?\\n")) {
                    logger.info(line);
                }
            }
        });

        System.setErr(new PrintStream(System.err) {
            @Override
            public void println(String s) {
            	for (String line : s.split("\\r?\\n")) {
                    logger.error(line);
                }
            }
        });
        
		SpringApplication.run(DwisCostApplication.class, args);
	}

}
