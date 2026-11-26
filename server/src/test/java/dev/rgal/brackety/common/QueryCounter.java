package dev.rgal.brackety.common;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import java.sql.Connection;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import javax.sql.DataSource;
import org.springframework.beans.factory.config.BeanPostProcessor;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;

/** Records the SQL statements the app prepares, JPA and JDBC alike. Import it into a test to measure. */
@TestConfiguration(proxyBeanMethods = false)
public class QueryCounter {

    private static final List<String> STATEMENTS = Collections.synchronizedList(new ArrayList<>());

    public static void reset() {
        STATEMENTS.clear();
    }

    /** Since the last {@link #reset()}, in order. */
    public static List<String> statements() {
        return List.copyOf(STATEMENTS);
    }

    @Bean
    static BeanPostProcessor countingDataSource() {
        return new BeanPostProcessor() {
            @Override
            public Object postProcessAfterInitialization(Object bean, String name) {
                return bean instanceof DataSource dataSource ? counting(dataSource) : bean;
            }
        };
    }

    private static DataSource counting(DataSource target) {
        return (DataSource) Proxy.newProxyInstance(
                QueryCounter.class.getClassLoader(), new Class<?>[] {DataSource.class}, (proxy, method, args) -> {
                    var result = invoke(target, method, args);
                    return result instanceof Connection connection ? counting(connection) : result;
                });
    }

    private static Connection counting(Connection target) {
        return (Connection) Proxy.newProxyInstance(
                QueryCounter.class.getClassLoader(), new Class<?>[] {Connection.class}, (proxy, method, args) -> {
                    var name = method.getName();
                    if (name.equals("prepareStatement")
                            || name.equals("prepareCall")
                            || name.equals("createStatement")) {
                        STATEMENTS.add(args != null && args.length > 0 && args[0] instanceof String sql ? sql : name);
                    }
                    return invoke(target, method, args);
                });
    }

    private static Object invoke(Object target, Method method, Object[] args) throws Throwable {
        try {
            return method.invoke(target, args);
        } catch (InvocationTargetException e) {
            throw e.getCause();
        }
    }
}
