FROM microsoft/azure-cli:2.0.57

COPY pipe /
RUN chmod a+x /*.sh

ENTRYPOINT ["/pipe.sh"]
