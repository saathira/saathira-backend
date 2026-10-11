const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function run() {
  const users = await prisma.user.findMany({
    include: { companion: true }
  });
  console.log('COUNT:', users.length);
  console.log('USERS:', JSON.stringify(users, null, 2));
  await prisma.$disconnect();
}

run().catch(console.error);
