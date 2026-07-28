import { BadRequestException } from '@nestjs/common';
import { StorageService } from './storage.service';

function file(overrides: Partial<{ mimetype: string; size: number; originalname: string }> = {}) {
  return {
    buffer: Buffer.from('test'),
    mimetype: 'image/jpeg',
    size: 1024,
    originalname: 'photo.jpg',
    ...overrides,
  };
}

describe('StorageService', () => {
  const service = new StorageService();

  describe('buildKey', () => {
    it('namespaces by scope and owner so one owner cannot overwrite another', () => {
      const key = service.buildKey('vehicle-docs', 'vehicle-1', 'application/pdf');
      expect(key.startsWith('vehicle-docs/vehicle-1/')).toBe(true);
      expect(key.endsWith('.pdf')).toBe(true);
    });

    it('never reuses a key for the same owner and type', () => {
      const a = service.buildKey('listing-photos', 'user-1', 'image/png');
      const b = service.buildKey('listing-photos', 'user-1', 'image/png');
      expect(a).not.toEqual(b);
    });

    it('ignores the client-supplied filename when the mime type is known', () => {
      const key = service.buildKey('listing-photos', 'user-1', 'image/png', '../../evil.sh');
      expect(key).toMatch(/^listing-photos\/user-1\/[0-9a-f-]+\.png$/);
    });
  });

  describe('upload validation', () => {
    it('rejects a file type the scope does not allow', async () => {
      await expect(
        service.upload(file({ mimetype: 'application/x-msdownload' }), 'listing-photos', 'user-1'),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('rejects a PDF as a photo even though documents allow it', async () => {
      await expect(
        service.upload(file({ mimetype: 'application/pdf' }), 'vehicle-photos', 'v-1'),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('rejects a file over the scope size cap', async () => {
      await expect(
        service.upload(file({ size: 9 * 1024 * 1024 }), 'listing-photos', 'user-1'),
      ).rejects.toBeInstanceOf(BadRequestException);
    });
  });

  describe('isIssuedValue', () => {
    it('accepts a bare key for the scope', () => {
      expect(service.isIssuedValue('listing-photos/user-1/abc.jpg', 'listing-photos')).toBe(true);
    });

    it('accepts a full URL that we issued', () => {
      expect(
        service.isIssuedValue('https://cdn.example.com/listing-photos/user-1/abc.jpg', 'listing-photos'),
      ).toBe(true);
    });

    it('rejects an arbitrary external URL', () => {
      expect(service.isIssuedValue('https://evil.example.com/malware.exe', 'listing-photos')).toBe(false);
    });

    it('rejects a value issued for a different scope', () => {
      expect(service.isIssuedValue('vehicle-docs/v-1/abc.pdf', 'listing-photos')).toBe(false);
    });

    it('rejects a value that merely mentions the scope name', () => {
      expect(service.isIssuedValue('https://evil.example.com/?x=listing-photos/a.jpg', 'listing-photos')).toBe(
        false,
      );
    });
  });
});
