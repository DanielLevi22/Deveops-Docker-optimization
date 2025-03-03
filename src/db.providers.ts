import { DataSource } from 'typeorm';

export const databaseProviders = [
  {
    provide: 'DATA_SOURCE',
    useFactory: async () => {
      const dataSource = new DataSource({
        type: 'mysql',
        host: 'mysql',
        port: 3306,
        username: 'root',
        password: 'root',
        database: 'test',
        synchronize: true,
      });

      return dataSource.initialize();
    },
  },
];
