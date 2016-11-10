#++++++++++++++++++++++++++++++++++++++
# MySQL Docker container
#++++++++++++++++++++++++++++++++++++++
#
# Official images:
#
#   mysql   - official MySQL from Oracle
#             https://hub.docker.com/r/library/mysql/
#
#++++++++++++++++++++++++++++++++++++++

FROM mysql:5.6

ADD conf/mysql-docker.cnf /etc/mysql/conf.d/z99-docker.cnf