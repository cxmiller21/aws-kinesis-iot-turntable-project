package com.crowvinyl.iotturntables;

public class TurntableEvents {

  private class Event {
    private String turntableId;
    private String artist;
    private String album;
    private String song;
    private String play_timestamp;
    private int rpm;
    private int volume;
    private String speaker;
    private String owner;
    private String zip_code;
    private String wifi_name;
    private String wifi_speed;

    public void Event(String turntableId, String artist, String album, String song, String play_timestamp,
        int rpm, int volume, String speaker, String owner, String zip_code, String wifi_name, String wifi_speed) {
      this.turntableId = turntableId;
      this.artist = artist;
      this.album = album;
      this.song = song;
      this.play_timestamp = play_timestamp;
      this.rpm = rpm;
      this.volume = volume;
      this.speaker = speaker;
      this.owner = owner;
      this.zip_code = zip_code;
      this.wifi_name = wifi_name;
      this.wifi_speed = wifi_speed;
    }
  }

  /**
   * Generates a blob containing a UTF-8 string. The string begins with the
   * sequence number in decimal notation, followed by a space, followed by
   * padding.
   *
   * @param totalLen
   *                 Total length of the data. After the sequence number,
   *                 padding
   *                 is added until this length is reached.
   * @return ByteBuffer containing the blob
   */
  public static ByteBuffer generateIoTEvent() {
    // create a new Event object
    TurntableEvent event = new Event();
    // set the event properties
    event.turntableId = "turntable-1";
    event.artist = "The Beatles";
  }
}
