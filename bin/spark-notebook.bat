@REM spark-notebook launcher script
@REM
@REM Environment:
@REM JAVA_HOME - location of a JDK home dir (optional if java on path)
@REM CFG_OPTS  - JVM options (optional)
@REM Configuration:
@REM SPARK_NOTEBOOK_config.txt found in the SPARK_NOTEBOOK_HOME.
@setlocal enabledelayedexpansion

@echo off

if "%SPARK_NOTEBOOK_HOME%"=="" set "SPARK_NOTEBOOK_HOME=%~dp0\\.."

set "APP_LIB_DIR=%SPARK_NOTEBOOK_HOME%\lib\"

rem Detect if we were double clicked, although theoretically A user could
rem manually run cmd /c
for %%x in (!cmdcmdline!) do if %%~x==/c set DOUBLECLICKED=1

rem FIRST we load the config file of extra options.
set "CFG_FILE=%SPARK_NOTEBOOK_HOME%\SPARK_NOTEBOOK_config.txt"
set CFG_OPTS=
if exist %CFG_FILE% (
  FOR /F "tokens=* eol=# usebackq delims=" %%i IN ("%CFG_FILE%") DO (
    set DO_NOT_REUSE_ME=%%i
    rem ZOMG (Part #2) WE use !! here to delay the expansion of
    rem CFG_OPTS, otherwise it remains "" for this loop.
    set CFG_OPTS=!CFG_OPTS! !DO_NOT_REUSE_ME!
  )
)

rem We use the value of the JAVACMD environment variable if defined
set _JAVACMD=%JAVACMD%

if "%_JAVACMD%"=="" (
  if not "%JAVA_HOME%"=="" (
    if exist "%JAVA_HOME%\bin\java.exe" set "_JAVACMD=%JAVA_HOME%\bin\java.exe"
  )
)

if "%_JAVACMD%"=="" set _JAVACMD=java

rem Detect if this java is ok to use.
for /F %%j in ('"%_JAVACMD%" -version  2^>^&1') do (
  if %%~j==java set JAVAINSTALLED=1
  if %%~j==openjdk set JAVAINSTALLED=1
)

rem BAT has no logical or, so we do it OLD SCHOOL! Oppan Redmond Style
set JAVAOK=true
if not defined JAVAINSTALLED set JAVAOK=false

if "%JAVAOK%"=="false" (
  echo.
  echo A Java JDK is not installed or can't be found.
  if not "%JAVA_HOME%"=="" (
    echo JAVA_HOME = "%JAVA_HOME%"
  )
  echo.
  echo Please go to
  echo   http://www.oracle.com/technetwork/java/javase/downloads/index.html
  echo and download a valid Java JDK and install before running spark-notebook.
  echo.
  echo If you think this message is in error, please check
  echo your environment variables to see if "java.exe" and "javac.exe" are
  echo available via JAVA_HOME or PATH.
  echo.
  if defined DOUBLECLICKED pause
  exit /B 1
)


rem We use the value of the JAVA_OPTS environment variable if defined, rather than the config.
set _JAVA_OPTS=%JAVA_OPTS%
if "!_JAVA_OPTS!"=="" set _JAVA_OPTS=!CFG_OPTS!

rem We keep in _JAVA_PARAMS all -J-prefixed and -D-prefixed arguments
rem "-J" is stripped, "-D" is left as is, and everything is appended to JAVA_OPTS
set _JAVA_PARAMS=
set _APP_ARGS=

:param_loop
call set _PARAM1=%%1
set "_TEST_PARAM=%~1"

if ["!_PARAM1!"]==[""] goto param_afterloop


rem ignore arguments that do not start with '-'
if "%_TEST_PARAM:~0,1%"=="-" goto param_java_check
set _APP_ARGS=!_APP_ARGS! !_PARAM1!
shift
goto param_loop

:param_java_check
if "!_TEST_PARAM:~0,2!"=="-J" (
  rem strip -J prefix
  set _JAVA_PARAMS=!_JAVA_PARAMS! !_TEST_PARAM:~2!
  shift
  goto param_loop
)

if "!_TEST_PARAM:~0,2!"=="-D" (
  rem test if this was double-quoted property "-Dprop=42"
  for /F "delims== tokens=1,*" %%G in ("!_TEST_PARAM!") DO (
    if not ["%%H"] == [""] (
      set _JAVA_PARAMS=!_JAVA_PARAMS! !_PARAM1!
    ) else if [%2] neq [] (
      rem it was a normal property: -Dprop=42 or -Drop="42"
      call set _PARAM1=%%1=%%2
      set _JAVA_PARAMS=!_JAVA_PARAMS! !_PARAM1!
      shift
    )
  )
) else (
  if "!_TEST_PARAM!"=="-main" (
    call set CUSTOM_MAIN_CLASS=%%2
    shift
  ) else (
    set _APP_ARGS=!_APP_ARGS! !_PARAM1!
  )
)
shift
goto param_loop
:param_afterloop

set _JAVA_OPTS=!_JAVA_OPTS! !_JAVA_PARAMS!
:run
 
set "APP_CLASSPATH=%APP_LIB_DIR%\noootsab.spark-notebook-0.6.0-scala-2.10.4-spark-1.4.1-hadoop-2.2.0.jar;%APP_LIB_DIR%\tachyon.tachyon-0.6.0-scala-2.10.4-spark-1.4.1-hadoop-2.2.0.jar;%APP_LIB_DIR%\subprocess.subprocess-0.6.0-scala-2.10.4-spark-1.4.1-hadoop-2.2.0.jar;%APP_LIB_DIR%\observable.observable-0.6.0-scala-2.10.4-spark-1.4.1-hadoop-2.2.0.jar;%APP_LIB_DIR%\common.common-0.6.0-scala-2.10.4-spark-1.4.1-hadoop-2.2.0.jar;%APP_LIB_DIR%\spark.spark-0.6.0-scala-2.10.4-spark-1.4.1-hadoop-2.2.0.jar;%APP_LIB_DIR%\kernel.kernel-0.6.0-scala-2.10.4-spark-1.4.1-hadoop-2.2.0.jar;%APP_LIB_DIR%\wisp_2.10-0.0.5.jar;%APP_LIB_DIR%\org.scala-lang.scala-compiler-2.10.4.jar;%APP_LIB_DIR%\org.scala-lang.scala-library-2.10.4.jar;%APP_LIB_DIR%\org.scala-lang.scala-reflect-2.10.4.jar;%APP_LIB_DIR%\com.google.guava.guava-14.0.1.jar;%APP_LIB_DIR%\org.tachyonproject.tachyon-0.6.4.jar;%APP_LIB_DIR%\org.tachyonproject.tachyon-0.6.4-tests.jar;%APP_LIB_DIR%\io.netty.netty-all-4.0.23.Final.jar;%APP_LIB_DIR%\org.eclipse.jetty.jetty-jsp-7.6.15.v20140411.jar;%APP_LIB_DIR%\org.eclipse.jetty.orbit.javax.servlet.jsp-2.1.0.v201105211820.jar;%APP_LIB_DIR%\org.eclipse.jetty.orbit.org.apache.jasper.glassfish-2.1.0.v201110031002.jar;%APP_LIB_DIR%\org.eclipse.jetty.orbit.javax.servlet.jsp.jstl-1.2.0.v201105211821.jar;%APP_LIB_DIR%\org.eclipse.jetty.orbit.org.apache.taglibs.standard.glassfish-1.2.0.v201112081803.jar;%APP_LIB_DIR%\org.eclipse.jetty.orbit.javax.el-2.1.0.v201105211819.jar;%APP_LIB_DIR%\org.eclipse.jetty.orbit.com.sun.el-1.0.0.v201105211818.jar;%APP_LIB_DIR%\org.eclipse.jetty.orbit.org.eclipse.jdt.core-3.7.1.jar;%APP_LIB_DIR%\org.eclipse.jetty.jetty-webapp-7.6.15.v20140411.jar;%APP_LIB_DIR%\org.eclipse.jetty.jetty-xml-7.6.15.v20140411.jar;%APP_LIB_DIR%\org.eclipse.jetty.jetty-util-7.6.15.v20140411.jar;%APP_LIB_DIR%\org.eclipse.jetty.jetty-servlet-7.6.15.v20140411.jar;%APP_LIB_DIR%\org.eclipse.jetty.jetty-security-7.6.15.v20140411.jar;%APP_LIB_DIR%\org.eclipse.jetty.jetty-server-7.6.15.v20140411.jar;%APP_LIB_DIR%\org.eclipse.jetty.jetty-continuation-7.6.15.v20140411.jar;%APP_LIB_DIR%\org.eclipse.jetty.jetty-http-7.6.15.v20140411.jar;%APP_LIB_DIR%\org.eclipse.jetty.jetty-io-7.6.15.v20140411.jar;%APP_LIB_DIR%\log4j.log4j-1.2.16.jar;%APP_LIB_DIR%\commons-codec.commons-codec-1.10.jar;%APP_LIB_DIR%\commons-io.commons-io-2.4.jar;%APP_LIB_DIR%\org.apache.zookeeper.zookeeper-3.4.5.jar;%APP_LIB_DIR%\xmlenc.xmlenc-0.52.jar;%APP_LIB_DIR%\org.apache.commons.commons-math-2.1.jar;%APP_LIB_DIR%\commons-configuration.commons-configuration-1.6.jar;%APP_LIB_DIR%\commons-collections.commons-collections-3.2.1.jar;%APP_LIB_DIR%\commons-logging.commons-logging-1.1.1.jar;%APP_LIB_DIR%\commons-digester.commons-digester-1.8.jar;%APP_LIB_DIR%\commons-beanutils.commons-beanutils-1.7.0.jar;%APP_LIB_DIR%\commons-beanutils.commons-beanutils-core-1.8.0.jar;%APP_LIB_DIR%\oro.oro-2.0.8.jar;%APP_LIB_DIR%\org.tachyonproject.tachyon-client-0.6.4.jar;%APP_LIB_DIR%\com.typesafe.play.play_2.10-2.3.7.jar;%APP_LIB_DIR%\com.typesafe.play.build-link-2.3.7.jar;%APP_LIB_DIR%\com.typesafe.play.play-exceptions-2.3.7.jar;%APP_LIB_DIR%\org.javassist.javassist-3.18.2-GA.jar;%APP_LIB_DIR%\org.scala-stm.scala-stm_2.10-0.7.jar;%APP_LIB_DIR%\com.typesafe.config-1.2.1.jar;%APP_LIB_DIR%\org.joda.joda-convert-1.6.jar;%APP_LIB_DIR%\com.typesafe.play.twirl-api_2.10-1.0.2.jar;%APP_LIB_DIR%\io.netty.netty-3.9.3.Final.jar;%APP_LIB_DIR%\com.typesafe.netty.netty-http-pipelining-1.1.2.jar;%APP_LIB_DIR%\ch.qos.logback.logback-core-1.1.1.jar;%APP_LIB_DIR%\ch.qos.logback.logback-classic-1.1.1.jar;%APP_LIB_DIR%\xerces.xercesImpl-2.11.0.jar;%APP_LIB_DIR%\xml-apis.xml-apis-1.4.01.jar;%APP_LIB_DIR%\javax.transaction.jta-1.1.jar;%APP_LIB_DIR%\org.spark-project.akka.akka-actor_2.10-2.3.4-spark.jar;%APP_LIB_DIR%\org.spark-project.akka.akka-remote_2.10-2.3.4-spark.jar;%APP_LIB_DIR%\org.spark-project.protobuf.protobuf-java-2.5.0-spark.jar;%APP_LIB_DIR%\org.uncommons.maths.uncommons-maths-1.2.2a.jar;%APP_LIB_DIR%\org.spark-project.akka.akka-slf4j_2.10-2.3.4-spark.jar;%APP_LIB_DIR%\org.apache.commons.commons-exec-1.3.jar;%APP_LIB_DIR%\com.github.fommil.netlib.core-1.1.2.jar;%APP_LIB_DIR%\net.sourceforge.f2j.arpack_combined_all-0.1.jar;%APP_LIB_DIR%\net.sourceforge.f2j.arpack_combined_all-0.1-javadoc.jar;%APP_LIB_DIR%\net.sf.opencsv.opencsv-2.3.jar;%APP_LIB_DIR%\com.github.rwl.jtransforms-2.4.0.jar;%APP_LIB_DIR%\org.spire-math.spire_2.10-0.7.4.jar;%APP_LIB_DIR%\org.spire-math.spire-macros_2.10-0.7.4.jar;%APP_LIB_DIR%\org.apache.spark.spark-core_2.10-1.4.1.jar;%APP_LIB_DIR%\com.twitter.chill_2.10-0.5.0.jar;%APP_LIB_DIR%\com.twitter.chill-java-0.5.0.jar;%APP_LIB_DIR%\com.esotericsoftware.kryo.kryo-2.21.jar;%APP_LIB_DIR%\com.esotericsoftware.reflectasm.reflectasm-1.07-shaded.jar;%APP_LIB_DIR%\com.esotericsoftware.minlog.minlog-1.2.jar;%APP_LIB_DIR%\org.objenesis.objenesis-1.2.jar;%APP_LIB_DIR%\org.apache.spark.spark-launcher_2.10-1.4.1.jar;%APP_LIB_DIR%\org.spark-project.spark.unused-1.0.0.jar;%APP_LIB_DIR%\org.apache.spark.spark-network-common_2.10-1.4.1.jar;%APP_LIB_DIR%\org.apache.spark.spark-network-shuffle_2.10-1.4.1.jar;%APP_LIB_DIR%\org.apache.spark.spark-unsafe_2.10-1.4.1.jar;%APP_LIB_DIR%\com.google.code.findbugs.jsr305-1.3.9.jar;%APP_LIB_DIR%\net.java.dev.jets3t.jets3t-0.7.1.jar;%APP_LIB_DIR%\commons-httpclient.commons-httpclient-3.1.jar;%APP_LIB_DIR%\org.apache.curator.curator-recipes-2.4.0.jar;%APP_LIB_DIR%\org.apache.curator.curator-framework-2.4.0.jar;%APP_LIB_DIR%\org.apache.curator.curator-client-2.4.0.jar;%APP_LIB_DIR%\org.eclipse.jetty.orbit.javax.servlet-3.0.0.v201112011016.jar;%APP_LIB_DIR%\org.apache.commons.commons-lang3-3.3.2.jar;%APP_LIB_DIR%\org.apache.commons.commons-math3-3.4.1.jar;%APP_LIB_DIR%\org.slf4j.slf4j-api-1.7.10.jar;%APP_LIB_DIR%\org.slf4j.jul-to-slf4j-1.7.10.jar;%APP_LIB_DIR%\org.slf4j.jcl-over-slf4j-1.7.10.jar;%APP_LIB_DIR%\org.slf4j.slf4j-log4j12-1.7.10.jar;%APP_LIB_DIR%\com.ning.compress-lzf-1.0.3.jar;%APP_LIB_DIR%\org.xerial.snappy.snappy-java-1.1.1.7.jar;%APP_LIB_DIR%\net.jpountz.lz4.lz4-1.2.0.jar;%APP_LIB_DIR%\org.roaringbitmap.RoaringBitmap-0.4.5.jar;%APP_LIB_DIR%\org.json4s.json4s-jackson_2.10-3.2.10.jar;%APP_LIB_DIR%\org.json4s.json4s-core_2.10-3.2.10.jar;%APP_LIB_DIR%\org.json4s.json4s-ast_2.10-3.2.10.jar;%APP_LIB_DIR%\com.thoughtworks.paranamer.paranamer-2.6.jar;%APP_LIB_DIR%\org.scala-lang.scalap-2.10.0.jar;%APP_LIB_DIR%\com.fasterxml.jackson.core.jackson-databind-2.4.4.jar;%APP_LIB_DIR%\com.fasterxml.jackson.core.jackson-core-2.4.4.jar;%APP_LIB_DIR%\com.sun.jersey.jersey-server-1.9.jar;%APP_LIB_DIR%\com.sun.jersey.jersey-core-1.9.jar;%APP_LIB_DIR%\org.apache.mesos.mesos-0.21.1-shaded-protobuf.jar;%APP_LIB_DIR%\com.clearspring.analytics.stream-2.7.0.jar;%APP_LIB_DIR%\io.dropwizard.metrics.metrics-core-3.1.0.jar;%APP_LIB_DIR%\io.dropwizard.metrics.metrics-jvm-3.1.0.jar;%APP_LIB_DIR%\io.dropwizard.metrics.metrics-json-3.1.0.jar;%APP_LIB_DIR%\io.dropwizard.metrics.metrics-graphite-3.1.0.jar;%APP_LIB_DIR%\com.fasterxml.jackson.module.jackson-module-scala_2.10-2.4.4.jar;%APP_LIB_DIR%\com.fasterxml.jackson.core.jackson-annotations-2.4.4.jar;%APP_LIB_DIR%\net.razorvine.pyrolite-4.4.jar;%APP_LIB_DIR%\net.sf.py4j.py4j-0.8.2.1.jar;%APP_LIB_DIR%\org.apache.spark.spark-yarn_2.10-1.4.1.jar;%APP_LIB_DIR%\org.apache.spark.spark-sql_2.10-1.4.1.jar;%APP_LIB_DIR%\org.apache.spark.spark-catalyst_2.10-1.4.1.jar;%APP_LIB_DIR%\org.scalamacros.quasiquotes_2.10-2.0.1.jar;%APP_LIB_DIR%\org.jodd.jodd-core-3.6.3.jar;%APP_LIB_DIR%\org.apache.hadoop.hadoop-client-2.2.0.jar;%APP_LIB_DIR%\org.apache.hadoop.hadoop-common-2.2.0.jar;%APP_LIB_DIR%\org.apache.hadoop.hadoop-annotations-2.2.0.jar;%APP_LIB_DIR%\commons-cli.commons-cli-1.2.jar;%APP_LIB_DIR%\commons-net.commons-net-3.1.jar;%APP_LIB_DIR%\commons-lang.commons-lang-2.5.jar;%APP_LIB_DIR%\org.codehaus.jackson.jackson-core-asl-1.8.8.jar;%APP_LIB_DIR%\org.codehaus.jackson.jackson-mapper-asl-1.8.8.jar;%APP_LIB_DIR%\org.apache.avro.avro-1.7.4.jar;%APP_LIB_DIR%\org.apache.commons.commons-compress-1.4.1.jar;%APP_LIB_DIR%\org.tukaani.xz-1.0.jar;%APP_LIB_DIR%\com.google.protobuf.protobuf-java-2.5.0.jar;%APP_LIB_DIR%\org.apache.hadoop.hadoop-auth-2.2.0.jar;%APP_LIB_DIR%\org.apache.hadoop.hadoop-hdfs-2.2.0.jar;%APP_LIB_DIR%\org.mortbay.jetty.jetty-util-6.1.26.jar;%APP_LIB_DIR%\org.apache.hadoop.hadoop-mapreduce-client-app-2.2.0.jar;%APP_LIB_DIR%\org.apache.hadoop.hadoop-mapreduce-client-common-2.2.0.jar;%APP_LIB_DIR%\org.apache.hadoop.hadoop-yarn-common-2.2.0.jar;%APP_LIB_DIR%\org.apache.hadoop.hadoop-yarn-api-2.2.0.jar;%APP_LIB_DIR%\com.google.inject.guice-3.0.jar;%APP_LIB_DIR%\javax.inject.javax.inject-1.jar;%APP_LIB_DIR%\aopalliance.aopalliance-1.0.jar;%APP_LIB_DIR%\org.sonatype.sisu.inject.cglib-2.2.1-v20090111.jar;%APP_LIB_DIR%\asm.asm-3.2.jar;%APP_LIB_DIR%\com.sun.jersey.jersey-test-framework.jersey-test-framework-grizzly2-1.9.jar;%APP_LIB_DIR%\com.sun.jersey.jersey-json-1.9.jar;%APP_LIB_DIR%\org.codehaus.jettison.jettison-1.1.jar;%APP_LIB_DIR%\stax.stax-api-1.0.1.jar;%APP_LIB_DIR%\org.codehaus.jackson.jackson-jaxrs-1.8.8.jar;%APP_LIB_DIR%\org.codehaus.jackson.jackson-xc-1.8.8.jar;%APP_LIB_DIR%\com.sun.jersey.contribs.jersey-guice-1.9.jar;%APP_LIB_DIR%\org.apache.hadoop.hadoop-yarn-client-2.2.0.jar;%APP_LIB_DIR%\org.apache.hadoop.hadoop-mapreduce-client-core-2.2.0.jar;%APP_LIB_DIR%\org.apache.hadoop.hadoop-yarn-server-common-2.2.0.jar;%APP_LIB_DIR%\org.apache.hadoop.hadoop-mapreduce-client-shuffle-2.2.0.jar;%APP_LIB_DIR%\org.apache.hadoop.hadoop-mapreduce-client-jobclient-2.2.0.jar;%APP_LIB_DIR%\org.apache.spark.spark-repl_2.10-1.4.1.jar;%APP_LIB_DIR%\org.scala-lang.jline-2.10.4.jar;%APP_LIB_DIR%\org.fusesource.jansi.jansi-1.4.jar;%APP_LIB_DIR%\org.apache.spark.spark-bagel_2.10-1.4.1.jar;%APP_LIB_DIR%\org.apache.spark.spark-mllib_2.10-1.4.1.jar;%APP_LIB_DIR%\org.apache.spark.spark-streaming_2.10-1.4.1.jar;%APP_LIB_DIR%\org.apache.spark.spark-graphx_2.10-1.4.1.jar;%APP_LIB_DIR%\org.scalanlp.breeze_2.10-0.11.2.jar;%APP_LIB_DIR%\org.scalanlp.breeze-macros_2.10-0.11.2.jar;%APP_LIB_DIR%\org.jpmml.pmml-model-1.1.15.jar;%APP_LIB_DIR%\org.jpmml.pmml-agent-1.1.15.jar;%APP_LIB_DIR%\org.jpmml.pmml-schema-1.1.15.jar;%APP_LIB_DIR%\com.sun.xml.bind.jaxb-impl-2.2.7.jar;%APP_LIB_DIR%\com.sun.xml.bind.jaxb-core-2.2.7.jar;%APP_LIB_DIR%\javax.xml.bind.jaxb-api-2.2.7.jar;%APP_LIB_DIR%\com.sun.istack.istack-commons-runtime-2.16.jar;%APP_LIB_DIR%\com.sun.xml.fastinfoset.FastInfoset-1.2.12.jar;%APP_LIB_DIR%\javax.xml.bind.jsr173_api-1.0.jar;%APP_LIB_DIR%\org.apache.hadoop.hadoop-yarn-server-web-proxy-2.2.0.jar;%APP_LIB_DIR%\javax.servlet.servlet-api-2.5.jar;%APP_LIB_DIR%\com.google.inject.extensions.guice-servlet-3.0.jar;%APP_LIB_DIR%\io.reactivex.rxscala_2.10-0.22.0.jar;%APP_LIB_DIR%\io.reactivex.rxjava-1.0.0-rc.5.jar;%APP_LIB_DIR%\org.scalaz.scalaz-core_2.10-7.0.6.jar;%APP_LIB_DIR%\org.scala-sbt.sbt-0.13.8.jar;%APP_LIB_DIR%\org.scala-sbt.main-0.13.8.jar;%APP_LIB_DIR%\org.scala-sbt.actions-0.13.8.jar;%APP_LIB_DIR%\org.scala-sbt.classpath-0.13.8.jar;%APP_LIB_DIR%\org.scala-sbt.launcher-interface-0.13.8.jar;%APP_LIB_DIR%\org.scala-sbt.interface-0.13.8.jar;%APP_LIB_DIR%\org.scala-sbt.io-0.13.8.jar;%APP_LIB_DIR%\org.scala-sbt.control-0.13.8.jar;%APP_LIB_DIR%\org.scala-sbt.completion-0.13.8.jar;%APP_LIB_DIR%\org.scala-sbt.collections-0.13.8.jar;%APP_LIB_DIR%\jline.jline-2.11.jar;%APP_LIB_DIR%\org.scala-sbt.api-0.13.8.jar;%APP_LIB_DIR%\org.scala-sbt.compiler-integration-0.13.8.jar;%APP_LIB_DIR%\org.scala-sbt.incremental-compiler-0.13.8.jar;%APP_LIB_DIR%\org.scala-sbt.logging-0.13.8.jar;%APP_LIB_DIR%\org.scala-sbt.process-0.13.8.jar;%APP_LIB_DIR%\org.scala-sbt.relation-0.13.8.jar;%APP_LIB_DIR%\org.scala-sbt.compile-0.13.8.jar;%APP_LIB_DIR%\org.scala-sbt.classfile-0.13.8.jar;%APP_LIB_DIR%\org.scala-sbt.persist-0.13.8.jar;%APP_LIB_DIR%\org.scala-tools.sbinary.sbinary_2.10-0.4.2.jar;%APP_LIB_DIR%\org.scala-sbt.compiler-ivy-integration-0.13.8.jar;%APP_LIB_DIR%\org.scala-sbt.ivy-0.13.8.jar;%APP_LIB_DIR%\org.scala-sbt.cross-0.13.8.jar;%APP_LIB_DIR%\org.scala-sbt.ivy.ivy-2.3.0-sbt-fccfbd44c9f64523b61398a0155784dcbaeae28f.jar;%APP_LIB_DIR%\com.jcraft.jsch-0.1.46.jar;%APP_LIB_DIR%\org.scala-sbt.serialization_2.10-0.1.1.jar;%APP_LIB_DIR%\org.scala-lang.modules.scala-pickling_2.10-0.10.0.jar;%APP_LIB_DIR%\org.spire-math.jawn-parser_2.10-0.6.0.jar;%APP_LIB_DIR%\org.spire-math.json4s-support_2.10-0.6.0.jar;%APP_LIB_DIR%\org.scala-sbt.run-0.13.8.jar;%APP_LIB_DIR%\org.scala-sbt.task-system-0.13.8.jar;%APP_LIB_DIR%\org.scala-sbt.tasks-0.13.8.jar;%APP_LIB_DIR%\org.scala-sbt.tracking-0.13.8.jar;%APP_LIB_DIR%\org.scala-sbt.cache-0.13.8.jar;%APP_LIB_DIR%\org.scala-sbt.testing-0.13.8.jar;%APP_LIB_DIR%\org.scala-sbt.test-agent-0.13.8.jar;%APP_LIB_DIR%\org.scala-sbt.test-interface-1.0.jar;%APP_LIB_DIR%\org.scala-sbt.main-settings-0.13.8.jar;%APP_LIB_DIR%\org.scala-sbt.apply-macro-0.13.8.jar;%APP_LIB_DIR%\org.scala-sbt.command-0.13.8.jar;%APP_LIB_DIR%\org.scala-sbt.logic-0.13.8.jar;%APP_LIB_DIR%\org.scala-sbt.compiler-interface--bin-0.13.8.jar;%APP_LIB_DIR%\org.scala-sbt.compiler-interface--src-0.13.8.jar;%APP_LIB_DIR%\org.scala-sbt.precompiled-2_8_2-compiler-interface-bin-0.13.8.jar;%APP_LIB_DIR%\org.scala-sbt.precompiled-2_9_2-compiler-interface-bin-0.13.8.jar;%APP_LIB_DIR%\org.scala-sbt.precompiled-2_9_3-compiler-interface-bin-0.13.8.jar;%APP_LIB_DIR%\com.frugalmechanic.fm-sbt-s3-resolver-0.5.0.jar;%APP_LIB_DIR%\com.amazonaws.aws-java-sdk-s3-1.9.0.jar;%APP_LIB_DIR%\com.amazonaws.aws-java-sdk-core-1.9.0.jar;%APP_LIB_DIR%\org.apache.httpcomponents.httpclient-4.2.jar;%APP_LIB_DIR%\org.apache.httpcomponents.httpcore-4.2.jar;%APP_LIB_DIR%\joda-time.joda-time-2.8.1.jar;%APP_LIB_DIR%\io.continuum.bokeh.bokeh_2.10-0.2.jar;%APP_LIB_DIR%\io.continuum.bokeh.core_2.10-0.2.jar;%APP_LIB_DIR%\com.typesafe.play.play-json_2.10-2.4.0-M1.jar;%APP_LIB_DIR%\com.typesafe.play.play-iteratees_2.10-2.4.0-M1.jar;%APP_LIB_DIR%\com.typesafe.play.play-functional_2.10-2.4.0-M1.jar;%APP_LIB_DIR%\com.typesafe.play.play-datacommons_2.10-2.4.0-M1.jar;%APP_LIB_DIR%\io.continuum.bokeh.bokehjs_2.10-0.2.jar;%APP_LIB_DIR%\com.github.scala-incubator.io.scala-io-core_2.10-0.4.3.jar;%APP_LIB_DIR%\com.jsuereth.scala-arm_2.10-1.3.jar;%APP_LIB_DIR%\com.github.scala-incubator.io.scala-io-file_2.10-0.4.3.jar;%APP_LIB_DIR%\com.quantifind.sumac_2.10-0.3.0.jar;%APP_LIB_DIR%\com.typesafe.play.play-cache_2.10-2.3.7.jar;%APP_LIB_DIR%\net.sf.ehcache.ehcache-core-2.6.8.jar;%APP_LIB_DIR%\noootsab.spark-notebook-0.6.0-scala-2.10.4-spark-1.4.1-hadoop-2.2.0-assets.jar"
set "APP_MAIN_CLASS=play.core.server.NettyServer"

if defined CUSTOM_MAIN_CLASS (
    set MAIN_CLASS=!CUSTOM_MAIN_CLASS!
) else (
    set MAIN_CLASS=!APP_MAIN_CLASS!
)

rem Call the application and pass all arguments unchanged.
"%_JAVACMD%" !_JAVA_OPTS! !SPARK_NOTEBOOK_OPTS! -cp "%APP_CLASSPATH%" %MAIN_CLASS% !_APP_ARGS!

@endlocal


:end

exit /B %ERRORLEVEL%
