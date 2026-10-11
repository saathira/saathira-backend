import { PrismaClient, UserRole, UserStatus, VerificationStatus } from '@prisma/client';

const prisma = new PrismaClient();

const DEFAULT_ACTIVITIES = [
  { slug: 'shopping', name: 'Shopping', description: 'Assistance and companionship during mall and retail shopping' },
  { slug: 'doctor-visit', name: 'Doctor Visit', description: 'Accompany to medical checkups, appointments and waiting areas' },
  { slug: 'movies', name: 'Movies & Events', description: 'Join for cinema shows, concerts, exhibitions and theatre' },
  { slug: 'cafe-dinner', name: 'Cafe & Dining', description: 'Casual dining, coffee chats and foodie explorations' },
  { slug: 'city-exploration', name: 'City Exploration', description: 'Walks, tourist hotspots, parks and neighborhood tours' },
  { slug: 'conversation', name: 'Social Conversation', description: 'Friendly conversations, emotional support and discussions' },
];

interface CompanionSeedData {
  firebaseUid: string;
  fullName: string;
  phone: string;
  email: string;
  city: string;
  gender: string;
  dateOfBirth: Date;
  bio: string;
  languages: string[];
  hourlyRate: number; // in paise
  latitude: number;
  longitude: number;
  serviceRadiusKm: number;
  ratingAvg: number;
  ratingCount: number;
  payoutUpi: string;
  activitySlugs: string[];
}

const COMPANIONS_SEED: CompanionSeedData[] = [
  {
    firebaseUid: 'comp-uid-001',
    fullName: 'Aarav Mehta',
    phone: '+919820011001',
    email: 'aarav.mehta@saathira.com',
    city: 'Mumbai',
    gender: 'MALE',
    dateOfBirth: new Date('1997-04-15'),
    bio: 'Friendly corporate professional & local explorer. Love guiding people around South Mumbai art districts, heritage cafes, and museum exhibitions.',
    languages: ['English', 'Hindi', 'Gujarati', 'Marathi'],
    hourlyRate: 60000,
    latitude: 18.9220,
    longitude: 72.8347,
    serviceRadiusKm: 15,
    ratingAvg: 4.9,
    ratingCount: 42,
    payoutUpi: 'aarav.mehta@oksbi',
    activitySlugs: ['city-exploration', 'cafe-dinner', 'shopping', 'conversation'],
  },
  {
    firebaseUid: 'comp-uid-002',
    fullName: 'Ananya Sharma',
    phone: '+919820011002',
    email: 'ananya.sharma@saathira.com',
    city: 'Mumbai',
    gender: 'FEMALE',
    dateOfBirth: new Date('1998-08-22'),
    bio: 'Certified yoga practitioner and empathetic listener. Calm companion for doctor visits, wellness shopping, and peaceful walking tours.',
    languages: ['English', 'Hindi', 'Marathi'],
    hourlyRate: 50000,
    latitude: 19.0596,
    longitude: 72.8295,
    serviceRadiusKm: 20,
    ratingAvg: 4.95,
    ratingCount: 58,
    payoutUpi: 'ananya.sharma@okaxis',
    activitySlugs: ['doctor-visit', 'conversation', 'shopping', 'cafe-dinner'],
  },
  {
    firebaseUid: 'comp-uid-003',
    fullName: 'Rohan Deshmukh',
    phone: '+919820011003',
    email: 'rohan.deshmukh@saathira.com',
    city: 'Pune',
    gender: 'MALE',
    dateOfBirth: new Date('1996-11-10'),
    bio: 'Tech enthusiast & foodie. Happy to accompany you to tech events, FC road food trails, cinema shows, and heritage walks.',
    languages: ['English', 'Hindi', 'Marathi'],
    hourlyRate: 45000,
    latitude: 18.5204,
    longitude: 73.8567,
    serviceRadiusKm: 15,
    ratingAvg: 4.85,
    ratingCount: 31,
    payoutUpi: 'rohan.deshmukh@icici',
    activitySlugs: ['movies', 'cafe-dinner', 'city-exploration', 'conversation'],
  },
  {
    firebaseUid: 'comp-uid-004',
    fullName: 'Pooja Nair',
    phone: '+919820011004',
    email: 'pooja.nair@saathira.com',
    city: 'Bengaluru',
    gender: 'FEMALE',
    dateOfBirth: new Date('1995-02-18'),
    bio: 'Fashion consultant and retail therapy expert. Patient companion for wardrobe updates, mall shopping, and book cafe visits.',
    languages: ['English', 'Hindi', 'Kannada', 'Malayalam'],
    hourlyRate: 75000,
    latitude: 12.9716,
    longitude: 77.5946,
    serviceRadiusKm: 25,
    ratingAvg: 5.0,
    ratingCount: 64,
    payoutUpi: 'pooja.nair@okhdfcbank',
    activitySlugs: ['shopping', 'cafe-dinner', 'conversation', 'movies'],
  },
  {
    firebaseUid: 'comp-uid-005',
    fullName: 'Vikramaditya Verma',
    phone: '+919820011005',
    email: 'vikram.verma@saathira.com',
    city: 'Delhi NCR',
    gender: 'MALE',
    dateOfBirth: new Date('1994-06-30'),
    bio: 'Former hospitality manager. Dependable companion for hospital visits, administrative errands, and CP dining outings.',
    languages: ['English', 'Hindi', 'Punjabi'],
    hourlyRate: 55000,
    latitude: 28.6139,
    longitude: 77.2090,
    serviceRadiusKm: 20,
    ratingAvg: 4.88,
    ratingCount: 39,
    payoutUpi: 'vikram.verma@paytm',
    activitySlugs: ['doctor-visit', 'conversation', 'cafe-dinner', 'shopping'],
  },
  {
    firebaseUid: 'comp-uid-006',
    fullName: 'Meera Iyer',
    phone: '+919820011006',
    email: 'meera.iyer@saathira.com',
    city: 'Chennai',
    gender: 'FEMALE',
    dateOfBirth: new Date('1999-01-14'),
    bio: 'Carnatic music enthusiast & literature lover. Great company for concerts, art galleries, beach walks, and quiet coffee conversations.',
    languages: ['English', 'Tamil', 'Hindi'],
    hourlyRate: 50000,
    latitude: 13.0827,
    longitude: 80.2707,
    serviceRadiusKm: 15,
    ratingAvg: 4.92,
    ratingCount: 27,
    payoutUpi: 'meera.iyer@sbi',
    activitySlugs: ['movies', 'conversation', 'city-exploration', 'cafe-dinner'],
  },
  {
    firebaseUid: 'comp-uid-007',
    fullName: 'Kabir Sen',
    phone: '+919820011007',
    email: 'kabir.sen@saathira.com',
    city: 'Kolkata',
    gender: 'MALE',
    dateOfBirth: new Date('1995-09-05'),
    bio: 'Architecture buff and street photography enthusiast. Eager to explore historic streets, heritage cafes, and book fairs with you.',
    languages: ['English', 'Bengali', 'Hindi'],
    hourlyRate: 40000,
    latitude: 22.5726,
    longitude: 88.3639,
    serviceRadiusKm: 15,
    ratingAvg: 4.8,
    ratingCount: 22,
    payoutUpi: 'kabir.sen@ybl',
    activitySlugs: ['city-exploration', 'cafe-dinner', 'movies', 'conversation'],
  },
  {
    firebaseUid: 'comp-uid-008',
    fullName: 'Tanvi Kulkarni',
    phone: '+919820011008',
    email: 'tanvi.kulkarni@saathira.com',
    city: 'Mumbai',
    gender: 'FEMALE',
    dateOfBirth: new Date('1997-12-03'),
    bio: 'Warm and compassionate elder-care volunteer. Specializes in doctor visit assistance, pharmacy runs, and patient accompaniment.',
    languages: ['English', 'Hindi', 'Marathi'],
    hourlyRate: 60000,
    latitude: 19.1136,
    longitude: 72.8697,
    serviceRadiusKm: 18,
    ratingAvg: 4.96,
    ratingCount: 49,
    payoutUpi: 'tanvi.kulkarni@okaxis',
    activitySlugs: ['doctor-visit', 'conversation', 'shopping'],
  },
  {
    firebaseUid: 'comp-uid-009',
    fullName: 'Siddharth Rao',
    phone: '+919820011009',
    email: 'siddharth.rao@saathira.com',
    city: 'Hyderabad',
    gender: 'MALE',
    dateOfBirth: new Date('1996-03-27'),
    bio: 'Film buff & gourmet food explorer. Perfect partner for latest IMAX blockbusters, food festivals, and weekend outings in Jubilee Hills.',
    languages: ['English', 'Telugu', 'Hindi'],
    hourlyRate: 50000,
    latitude: 17.3850,
    longitude: 78.4867,
    serviceRadiusKm: 20,
    ratingAvg: 4.87,
    ratingCount: 33,
    payoutUpi: 'siddharth.rao@kotak',
    activitySlugs: ['movies', 'cafe-dinner', 'city-exploration', 'shopping'],
  },
  {
    firebaseUid: 'comp-uid-010',
    fullName: 'Ishita Patel',
    phone: '+919820011010',
    email: 'ishita.patel@saathira.com',
    city: 'Ahmedabad',
    gender: 'FEMALE',
    dateOfBirth: new Date('1998-05-19'),
    bio: 'Textile designer & artisan market guide. Love accompanying folks for shopping exhibitions, textile tours, and riverfront evening strolls.',
    languages: ['English', 'Gujarati', 'Hindi'],
    hourlyRate: 45000,
    latitude: 23.0225,
    longitude: 72.5714,
    serviceRadiusKm: 15,
    ratingAvg: 4.9,
    ratingCount: 29,
    payoutUpi: 'ishita.patel@oksbi',
    activitySlugs: ['shopping', 'city-exploration', 'conversation', 'cafe-dinner'],
  },
  {
    firebaseUid: 'comp-uid-011',
    fullName: 'Arjun Singhania',
    phone: '+919820011011',
    email: 'arjun.singhania@saathira.com',
    city: 'Jaipur',
    gender: 'MALE',
    dateOfBirth: new Date('1995-10-12'),
    bio: 'Heritage hotelier and cultural ambassador. Ideal companion for fort exploration, jewelry shopping, and traditional dining experiences.',
    languages: ['English', 'Hindi', 'Rajasthani'],
    hourlyRate: 65000,
    latitude: 26.9124,
    longitude: 75.7873,
    serviceRadiusKm: 20,
    ratingAvg: 4.94,
    ratingCount: 41,
    payoutUpi: 'arjun.singhania@icici',
    activitySlugs: ['city-exploration', 'shopping', 'cafe-dinner', 'movies'],
  },
  {
    firebaseUid: 'comp-uid-012',
    fullName: "Rhea D'Souza",
    phone: '+919820011012',
    email: 'rhea.dsouza@saathira.com',
    city: 'Goa',
    gender: 'FEMALE',
    dateOfBirth: new Date('1997-07-08'),
    bio: 'Lifelong Goa local & nature enthusiast. Happy to accompany for flea markets, indie cafe hopping, sunset beach walks, and art shows.',
    languages: ['English', 'Konkani', 'Hindi', 'Portuguese'],
    hourlyRate: 80000,
    latitude: 15.2993,
    longitude: 74.1240,
    serviceRadiusKm: 30,
    ratingAvg: 5.0,
    ratingCount: 55,
    payoutUpi: 'rhea.dsouza@okhdfcbank',
    activitySlugs: ['city-exploration', 'cafe-dinner', 'movies', 'shopping', 'conversation'],
  },
  {
    firebaseUid: 'comp-uid-013',
    fullName: 'Devendra Joshi',
    phone: '+919820011013',
    email: 'devendra.joshi@saathira.com',
    city: 'Mumbai',
    gender: 'MALE',
    dateOfBirth: new Date('1993-01-25'),
    bio: 'Patient listener and chess hobbyist. Great conversationalist for senior citizens, walking tours around Marine Drive, and medical visits.',
    languages: ['English', 'Hindi', 'Marathi'],
    hourlyRate: 45000,
    latitude: 18.9438,
    longitude: 72.8232,
    serviceRadiusKm: 15,
    ratingAvg: 4.89,
    ratingCount: 38,
    payoutUpi: 'devendra.joshi@sbi',
    activitySlugs: ['conversation', 'doctor-visit', 'city-exploration', 'cafe-dinner'],
  },
  {
    firebaseUid: 'comp-uid-014',
    fullName: 'Kavya Reddy',
    phone: '+919820011014',
    email: 'kavya.reddy@saathira.com',
    city: 'Bengaluru',
    gender: 'FEMALE',
    dateOfBirth: new Date('1998-11-29'),
    bio: 'UI/UX designer & weekend cafe enthusiast. Love exploring specialty roasteries, pottery workshops, and comic/gaming events.',
    languages: ['English', 'Kannada', 'Telugu', 'Hindi'],
    hourlyRate: 60000,
    latitude: 12.9352,
    longitude: 77.6245,
    serviceRadiusKm: 20,
    ratingAvg: 4.93,
    ratingCount: 35,
    payoutUpi: 'kavya.reddy@paytm',
    activitySlugs: ['cafe-dinner', 'movies', 'conversation', 'shopping'],
  },
  {
    firebaseUid: 'comp-uid-015',
    fullName: 'Rajveer Singh',
    phone: '+919137953842',
    email: 'rajveer.singh@saathira.com',
    city: 'Mumbai',
    gender: 'MALE',
    dateOfBirth: new Date('1996-08-14'),
    bio: 'Friendly certified guide & fitness enthusiast. Patient and polite accompaniment for senior citizen outings, fitness walks, and mall shopping.',
    languages: ['English', 'Hindi', 'Punjabi', 'Marathi'],
    hourlyRate: 50000,
    latitude: 19.0760,
    longitude: 72.8777,
    serviceRadiusKm: 25,
    ratingAvg: 4.95,
    ratingCount: 52,
    payoutUpi: 'rajveer.singh@okaxis',
    activitySlugs: ['shopping', 'doctor-visit', 'city-exploration', 'cafe-dinner', 'movies', 'conversation'],
  },
];

async function main() {
  // 1. Seed Activities
  const activityMap = new Map<string, string>();
  for (const act of DEFAULT_ACTIVITIES) {
    const record = await prisma.activity.upsert({
      where: { slug: act.slug },
      update: { name: act.name, description: act.description },
      create: act,
    });
    activityMap.set(act.slug, record.id);
  }
  console.log(`✅ Seeded ${DEFAULT_ACTIVITIES.length} default activities!`);

  // 2. Seed Super Admin
  await prisma.adminUser.upsert({
    where: { email: 'admin@saathira.com' },
    update: { isActive: true, role: 'SUPER_ADMIN' },
    create: {
      firebaseUid: 'dev-super-admin-uid',
      email: 'admin@saathira.com',
      name: 'Saathira Administrator',
      role: 'SUPER_ADMIN',
      isActive: true,
    },
  });
  console.log('✅ Seeded super admin user: admin@saathira.com');

  // 3. Seed 15 Verified Companions
  console.log(`🌱 Seeding ${COMPANIONS_SEED.length} verified companions...`);

  for (const item of COMPANIONS_SEED) {
    // Find or create User safely by firebaseUid or phone
    let user = await prisma.user.findFirst({
      where: {
        OR: [
          { firebaseUid: item.firebaseUid },
          { phone: item.phone },
        ],
      },
    });

    if (user) {
      user = await prisma.user.update({
        where: { id: user.id },
        data: {
          role: UserRole.COMPANION,
          status: UserStatus.ACTIVE,
          fullName: item.fullName,
          phone: item.phone,
          email: item.email,
          gender: item.gender,
          dateOfBirth: item.dateOfBirth,
          city: item.city,
        },
      });
    } else {
      user = await prisma.user.create({
        data: {
          firebaseUid: item.firebaseUid,
          role: UserRole.COMPANION,
          status: UserStatus.ACTIVE,
          fullName: item.fullName,
          phone: item.phone,
          email: item.email,
          gender: item.gender,
          dateOfBirth: item.dateOfBirth,
          city: item.city,
        },
      });
    }

    // Upsert Companion Profile
    const companion = await prisma.companion.upsert({
      where: { userId: user.id },
      update: {
        bio: item.bio,
        languages: item.languages,
        hourlyRate: item.hourlyRate,
        latitude: item.latitude,
        longitude: item.longitude,
        serviceRadiusKm: item.serviceRadiusKm,
        verificationStatus: VerificationStatus.APPROVED,
        isAvailable: true,
        ratingAvg: item.ratingAvg,
        ratingCount: item.ratingCount,
        payoutUpi: item.payoutUpi,
      },
      create: {
        userId: user.id,
        bio: item.bio,
        languages: item.languages,
        hourlyRate: item.hourlyRate,
        latitude: item.latitude,
        longitude: item.longitude,
        serviceRadiusKm: item.serviceRadiusKm,
        verificationStatus: VerificationStatus.APPROVED,
        isAvailable: true,
        ratingAvg: item.ratingAvg,
        ratingCount: item.ratingCount,
        payoutUpi: item.payoutUpi,
      },
    });

    // Link Companion Activities
    for (const slug of item.activitySlugs) {
      const activityId = activityMap.get(slug);
      if (activityId) {
        await prisma.companionActivity.upsert({
          where: {
            companionId_activityId: {
              companionId: companion.id,
              activityId,
            },
          },
          update: {},
          create: {
            companionId: companion.id,
            activityId,
          },
        });
      }
    }

    // Seed Availability (Mon-Sun: 9:00 AM - 9:00 PM)
    for (let day = 0; day <= 6; day++) {
      const existing = await prisma.availability.findFirst({
        where: { companionId: companion.id, dayOfWeek: day },
      });
      if (!existing) {
        await prisma.availability.create({
          data: {
            companionId: companion.id,
            dayOfWeek: day,
            startMinute: 540, // 09:00 AM
            endMinute: 1260,  // 09:00 PM
          },
        });
      }
    }

    // Seed Approved Verification Record
    const existingVerif = await prisma.companionVerification.findFirst({
      where: { companionId: companion.id },
    });
    if (!existingVerif) {
      await prisma.companionVerification.create({
        data: {
          companionId: companion.id,
          documentType: 'AADHAAR',
          documentPath: `verifications/${companion.id}/aadhaar.pdf`,
          selfiePath: `verifications/${companion.id}/selfie.jpg`,
          status: VerificationStatus.APPROVED,
          reviewedBy: 'dev-super-admin-uid',
          reviewNote: 'Verified identity and background check approved.',
          reviewedAt: new Date(),
        },
      });
    }

    console.log(`  ⭐ Seeded companion: ${item.fullName} (${item.city}) - ₹${item.hourlyRate / 100}/hr [Rating: ${item.ratingAvg}★]`);
  }

  console.log(`🎉 Successfully seeded all ${COMPANIONS_SEED.length} verified companions!`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
