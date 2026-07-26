import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateCmsContentDto } from './dto/create-cms-content.dto';
import { UpdateCmsContentDto } from './dto/update-cms-content.dto';

@Injectable()
export class CmsService {
  constructor(private readonly prisma: PrismaService) {}

  list(section?: string, locale?: string) {
    return this.prisma.cmsContent.findMany({
      where: { ...(section ? { section } : {}), ...(locale ? { locale } : {}) },
      orderBy: [{ section: 'asc' }, { order: 'asc' }],
    });
  }

  async getOne(id: string) {
    const content = await this.prisma.cmsContent.findUnique({ where: { id } });
    if (!content) throw new NotFoundException({ code: 'CMS_CONTENT_NOT_FOUND', message: 'Content not found.' });
    return content;
  }

  create(dto: CreateCmsContentDto) {
    return this.prisma.cmsContent.create({
      data: {
        section: dto.section,
        locale: dto.locale ?? 'en',
        title: dto.title,
        body: dto.body,
        order: dto.order ?? 0,
      },
    });
  }

  async update(id: string, dto: UpdateCmsContentDto) {
    await this.getOne(id);
    return this.prisma.cmsContent.update({ where: { id }, data: dto });
  }

  async remove(id: string) {
    await this.getOne(id);
    await this.prisma.cmsContent.delete({ where: { id } });
    return { success: true };
  }
}
