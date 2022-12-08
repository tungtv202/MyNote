package org.apache.james;


import static org.apache.james.MemoryJamesServerMain.IN_MEMORY_SERVER_AGGREGATE_MODULE;
import static org.apache.james.jmap.JMAPTestingConstants.BOB;
import static org.apache.james.jmap.JMAPTestingConstants.BOB_PASSWORD;
import static org.apache.james.jmap.JMAPTestingConstants.DOMAIN;

import java.io.File;
import java.util.List;
import java.util.stream.Collectors;

import org.apache.james.data.UsersRepositoryModuleChooser;
import org.apache.james.modules.data.MemoryUsersRepositoryModule;
import org.apache.james.utils.DataProbeImpl;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.io.TempDir;

public class MemoryImapModularTest implements ImapModularContract {
    @TempDir
    File temporaryFolder;

    private GuiceJamesServer jamesServer;

    @Override
    public GuiceJamesServer createJamesServer(List<String> imapPackages) {
        TemporaryJamesServer temporaryJamesServer = new TemporaryJamesServer(temporaryFolder);
        try {
            temporaryJamesServer.appendConfigurationFile(imapServerConfigurationTemplate(imapPackages), "imapserver.xml");
            jamesServer = temporaryJamesServer.getJamesServer().
                combineWith(IN_MEMORY_SERVER_AGGREGATE_MODULE)
                .combineWith(new UsersRepositoryModuleChooser(new MemoryUsersRepositoryModule())
                    .chooseModules(UsersRepositoryModuleChooser.Implementation.DEFAULT));
            jamesServer.start();
            jamesServer.getProbe(DataProbeImpl.class).fluent()
                .addDomain(DOMAIN)
                .addUser(BOB.asString(), BOB_PASSWORD);
            return jamesServer;
        } catch (Exception e) {
            throw new RuntimeException("Error when start James server", e);
        }
    }

    @AfterEach
    void afterEach() {
        if (jamesServer != null) {
            jamesServer.stop();
        }
    }

    public static String imapServerConfigurationTemplate(List<String> imapPackages) {
        String imapPackagesAppendValue = imapPackages.stream().map(p -> "<imapPackages>" + p + "</imapPackages>").collect(Collectors.joining("\n"));
        return String.format("<imapservers>\n" +
            "    <imapserver enabled=\"true\">\n" +
            "        <jmxName>imapserver</jmxName>\n" +
            "        <bind>0.0.0.0:0</bind>\n" +
            "        <connectionBacklog>200</connectionBacklog>\n" +
            "        <tls socketTLS=\"false\" startTLS=\"false\">\n" +
            "            <keystore>classpath://keystore</keystore>\n" +
            "            <secret>james72laBalle</secret>\n" +
            "            <provider>org.bouncycastle.jce.provider.BouncyCastleProvider</provider>\n" +
            "        </tls>\n" +
            "        <connectionLimit>0</connectionLimit>\n" +
            "        <connectionLimitPerIP>0</connectionLimitPerIP>\n" +
            "        <plainAuthDisallowed>false</plainAuthDisallowed>\n" +
            "        <gracefulShutdown>false</gracefulShutdown>\n" +
            "    </imapserver>\n" +
            "    <imapserver enabled=\"true\">\n" +
            "        <jmxName>imapserver-ssl</jmxName>\n" +
            "        <bind>0.0.0.0:0</bind>\n" +
            "        <connectionBacklog>200</connectionBacklog>\n" +
            "        <tls socketTLS=\"false\" startTLS=\"true\">\n" +
            "            <keystore>classpath://keystore</keystore>\n" +
            "            <secret>james72laBalle</secret>\n" +
            "            <provider>org.bouncycastle.jce.provider.BouncyCastleProvider</provider>\n" +
            "        </tls>\n" +
            "        <connectionLimit>0</connectionLimit>\n" +
            "        <connectionLimitPerIP>0</connectionLimitPerIP>\n" +
            "        <gracefulShutdown>false</gracefulShutdown>\n" +
            "    </imapserver>\n" +
            "     %s" +
            "</imapservers>", imapPackagesAppendValue);
    }

}
