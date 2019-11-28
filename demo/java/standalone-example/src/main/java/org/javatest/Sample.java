package org.javatest;
import java.io.*;
import org.apache.commons.math.fraction.Fraction;
import org.apache.commons.math.fraction.FractionFormat;
import org.apache.commons.io.HexDump;

public class Sample {
    public static void main(String[] args) {
		FractionFormat format = new FractionFormat(); // default format
		Fraction f = new Fraction(2, 4);
		String s = format.format(f); // s contains "1 / 2", note the reduced fraction
		System.out.println(String.valueOf(s));
        byte[] bytes = new byte[] { (byte)0x91, (byte)0xE9, 0x1D, (byte)0x98, 0x39, 0x01, 0x00, 0x00 };
        ByteArrayOutputStream os = new ByteArrayOutputStream();
        try {
            HexDump.dump(bytes, 0, os, 0);
            System.out.println(os.toString());
        } catch (Exception e) {
            System.out.println("Didn't work because of "+e);
        }
    }
}