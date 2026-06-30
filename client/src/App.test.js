import { render, screen } from '@testing-library/react';

jest.mock('react-router-dom', () => {
  const React = require('react');

  return {
    Link: ({ to, children, ...props }) =>
      React.createElement('a', { href: to, ...props }, children),
    useNavigate: () => jest.fn(),
  };
}, { virtual: true });

jest.mock('axios', () => ({
  post: jest.fn(),
}));

import Login from './features/auth/pages/Login';

test('renders RiderCraft authentication page', () => {
  render(<Login />);
  expect(screen.getAllByText(/RiderCraft/i).length).toBeGreaterThan(0);
});
