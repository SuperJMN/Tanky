using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;

namespace Game1
{
    /// <summary>
    /// This is the main type for your game.
    /// </summary>
    public class Game1 : Game
    {
        GraphicsDeviceManager graphics;
        SpriteBatch spriteBatch;
        private Texture2D goombaTexture;
        private readonly Tanky tanky;
        private float baseSpeed = 200F;
        private Texture2D background;

        public Game1()
        {
            graphics = new GraphicsDeviceManager(this);
            Content.RootDirectory = "Content";
            tanky = new Tanky();

            graphics.PreferredBackBufferWidth = 720;
            graphics.PreferredBackBufferWidth = 640;
            //graphics.ToggleFullScreen();
        }

        /// <summary>
        /// Allows the game to perform any initialization it needs to before starting to run.
        /// This is where it can query for any required services and load any non-graphic
        /// related content.  Calling base.Initialize will enumerate through any components
        /// and initialize them as well.
        /// </summary>
        protected override void Initialize()
        {
            base.Initialize();
        }

        /// <summary>
        /// LoadContent will be called once per game and is the place to load
        /// all of your content.
        /// </summary>
        protected override void LoadContent()
        {
            // Create a new SpriteBatch, which can be used to draw textures.
            spriteBatch = new SpriteBatch(GraphicsDevice);
            background = Content.Load<Texture2D>("Background");

            tanky.Load(Content);
        }

        /// <summary>
        /// UnloadContent will be called once per game and is the place to unload
        /// game-specific content.
        /// </summary>
        protected override void UnloadContent()
        {
            // TODO: Unload any non ContentManager content here
        }

        /// <summary>
        /// Allows the game to run logic such as updating the world,
        /// checking for collisions, gathering input, and playing audio.
        /// </summary>
        /// <param name="gameTime">Provides a snapshot of timing values.</param>
        protected override void Update(GameTime gameTime)
        {
            if (GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed || Keyboard.GetState().IsKeyDown(Keys.Escape))
                Exit();

            var kstate = Keyboard.GetState();

            if (kstate.IsKeyDown(Keys.Right))
            {
                tanky.Advance(gameTime.ElapsedGameTime);
            }
            else if (kstate.IsKeyDown(Keys.Left))
            {
                tanky.GoBack(gameTime.ElapsedGameTime);
            }

            if (kstate.IsKeyDown(Keys.Up))
            {
                if (tanky.Animation != Tanky.States.Jumping)
                {
                    tanky.Jump();
                    tanky.VerticalSpeed = -600;
                }
            }
            
            tanky.Top += tanky.VerticalSpeed * (float)gameTime.ElapsedGameTime.TotalSeconds;
            tanky.VerticalSpeed+=30;
            
            if (tanky.Top > Constants.GroundTop)
            {
                tanky.VerticalSpeed = 0;
                tanky.Top = Constants.GroundTop;
                tanky.Land();
            }

            base.Update(gameTime);
        }

        /// <summary>
        /// This is called when the game should draw itself.
        /// </summary>
        /// <param name="gameTime">Provides a snapshot of timing values.</param>
        protected override void Draw(GameTime gameTime)
        {
            spriteBatch.Begin();
            spriteBatch.Draw(background, GraphicsDevice.Viewport.Bounds, Color.White);
            tanky.Draw(spriteBatch);
            spriteBatch.End();

            base.Draw(gameTime);
        }
    }
}
