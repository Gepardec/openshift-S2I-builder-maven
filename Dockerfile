FROM centos:8

ARG S2IDIR="/home/s2i"
LABEL maintainer="Clemens Kaserer <clemens.kaserer@gmail.com>" \
      io.k8s.description="S2I builder for Java Applications" \
      io.k8s.display-name="Maven / Gradle Builder" \
      io.openshift.tags="builder,java,maven,gradle" \
      io.openshift.s2i.scripts-url="image://$S2IDIR/bin"

ARG APPDIR="/deployments"
ARG GRADLE_VERSION=5.6.2
ARG JAVA_VERSION=java-11-openjdk
RUN mkdir -p ${APPDIR}/target /opt/gradle && \
    yum install -y \
        ${JAVA_VERSION} \
        maven \
#        unzip && \
#    curl -Ls https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip > gradle-${GRADLE_VERSION}-bin.zip && \
#    unzip -d /opt/gradle gradle-${GRADLE_VERSION}-bin.zip && \
#    yum remove -y \
#        unzip && \
    yum clean all && \
#    rm gradle-${GRADLE_VERSION}-bin.zip && \
    chgrp -R 0 ${APPDIR}  /etc/maven  && \ 
    chmod -R g+rwX ${APPDIR} /opt/gradle /etc/maven

COPY s2i ${S2IDIR}
RUN chgrp -R 0 ${S2IDIR} && \
    chmod -R g+rwX ${S2IDIR}

ENV PATH=${PATH}:/opt/gradle/gradle-${GRADLE_VERSION}/bin

USER 1001

WORKDIR ${APPDIR}

CMD ["${S2IDIR}/bin/run"]
