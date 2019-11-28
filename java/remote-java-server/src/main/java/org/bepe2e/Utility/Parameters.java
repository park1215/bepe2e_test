package Utility;

import org.apache.logging.log4j.Level;
import org.apache.logging.log4j.core.config.Configurator;
import org.kohsuke.args4j.Option;

public class Parameters {
	enum LogLevel {
		TRACE,
		DEBUG,
		INFO,
		WARN,
		ERROR,
		FATAL,
	}

	@Option(name="-logLevel", usage="The log level")
	public void setLogLevel(LogLevel value) {
		String levelName = value.toString();
		Level level = Level.getLevel(levelName);
		Configurator.setRootLevel(level);
    }
}