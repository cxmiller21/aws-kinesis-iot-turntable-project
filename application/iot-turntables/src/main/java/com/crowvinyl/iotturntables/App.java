package com.crowvinyl.iotturntables;

import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.Executors;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicLong;

import com.amazonaws.auth.DefaultAWSCredentialsProviderChain;
import com.amazonaws.services.kinesis.producer.KinesisProducerConfiguration;
import com.amazonaws.services.kinesis.producer.KinesisProducer;
import com.amazonaws.services.kinesis.producer.UserRecordFailedException;
import com.amazonaws.services.kinesis.producer.UserRecordResult;
import com.google.common.util.concurrent.FutureCallback;
import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Hello world!
 *
 */
public class App {
  private static final Logger log = LoggerFactory.getLogger(App.class);

  private static final ScheduledExecutorService EXECUTOR = Executors.newScheduledThreadPool(1);

  /**
   * Timestamp we'll attach to every record
   */
  private static final String TIMESTAMP = Long.toString(System.currentTimeMillis());
  private static final String STREAM_NAME = "aws-kinesis-iot-turntable-stream";

  public static void main(String[] args) throws InterruptedException {

    KinesisProducerConfiguration config = new KinesisProducerConfiguration()
        .setRegion("us-east-1");

    log.info("Sending data to Kinesis Data Stream");
    log.info(String.format("Stream name: %s Region: us-east-1", STREAM_NAME));

    KinesisProducer kinesis = new KinesisProducer(config);

    // The monotonically increasing sequence number we will put in the data of each
    // record
    final AtomicLong sequenceNumber = new AtomicLong(0);

    // The number of records that have finished (either successfully put, or failed)
    final AtomicLong completed = new AtomicLong(0);

    // Push records and asynchronously check if they were successfully sent
    FutureCallback<UserRecordResult> myCallback = new FutureCallback<UserRecordResult>() {
      @Override
      public void onFailure(Throwable t) {
        /* Analyze and respond to the failure */
        log.error("Failed to send record to Kinesis Data Stream: " + t.getMessage());
      };

      @Override
      public void onSuccess(UserRecordResult result) {
        /* Respond to the success */
        completed.getAndIncrement();
        log.info("Successfully sent record to Kinesis Data Stream: " + result.toString());
      };
    };

    final ExecutorService callbackThreadPool = Executors.newCachedThreadPool();

    // This gives us progress updates
    EXECUTOR.scheduleAtFixedRate(new Runnable() {
      @Override
      public void run() {
        long put = sequenceNumber.get();
        long total = 5;
        double putPercent = 100.0 * put / total;
        long done = completed.get();
        double donePercent = 100.0 * done / total;
        log.info(String.format(
            "Put %d of %d so far (%.2f %%), %d have completed (%.2f %%)",
            put, total, putPercent, done, donePercent));
        log.info(String.format(
            "Oldest future as of now in millis is %s", kinesis.getOldestRecordTimeInMillis()));
      }
    }, 1, 1, TimeUnit.SECONDS);

    for (int i = 0; i < 500; ++i) {
      // data_string
      // ByteBuffer data = ByteBuffer.wrap("testing".getBytes(StandardCharsets.UTF_8));
      ByteBuffer data = Utils.generateData(sequenceNumber.get(), 128);
      ListenableFuture<UserRecordResult> f = kinesis.addUserRecord(STREAM_NAME, TIMESTAMP, data);
      log.info(String.format("Sending record # %s Timestamp: %s...", i, TIMESTAMP));
      // If the Future is complete by the time we call addCallback, the callback will
      // be invoked immediately.
      Futures.addCallback(f, myCallback, callbackThreadPool);
      sequenceNumber.getAndIncrement();
    }

    // Wait for puts to finish. After this statement returns, we have
    // finished all calls to putRecord, but the records may still be
    // in-flight. We will additionally wait for all records to actually
    // finish later.
    log.info("Waiting for puts to finish...");
    EXECUTOR.awaitTermination(60, TimeUnit.SECONDS);

    log.info("Completed sending records to Kinesis Data Stream!");
  }
}
