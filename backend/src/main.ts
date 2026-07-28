import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import type { NestExpressApplication } from '@nestjs/platform-express';
import { AppModule } from './app.module';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';
import { LOCAL_UPLOAD_DIR } from './storage/storage.provider';

async function bootstrap() {
  // rawBody is needed on `req.rawBody` for Stripe webhook signature
  // verification, which must run against the exact bytes Stripe sent.
  const app = await NestFactory.create<NestExpressApplication>(AppModule, {
    cors: true,
    rawBody: true,
  });

  // Serves the local-disk fallback used when R2 credentials aren't configured.
  // Sits outside the api/v1 prefix so stored URLs stay stable. With R2 set up,
  // nothing is written here and this route simply goes unused.
  app.useStaticAssets(LOCAL_UPLOAD_DIR, { prefix: '/uploads/' });

  app.setGlobalPrefix('api/v1');
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: false,
    }),
  );
  app.useGlobalFilters(new HttpExceptionFilter());

  const config = new DocumentBuilder()
    .setTitle('Car Nanny API')
    .setDescription('Car Nanny backend API — MVP surface (auth, vehicles, inspections, bookings, partners, payments, notifications, AI assistant)')
    .setVersion('0.1.0')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  const port = process.env.PORT ? parseInt(process.env.PORT, 10) : 3000;
  await app.listen(port);
  // eslint-disable-next-line no-console
  console.log(`Car Nanny API listening on http://localhost:${port}/api/v1`);
  // eslint-disable-next-line no-console
  console.log(`Swagger docs at http://localhost:${port}/api/docs`);
}
bootstrap();
